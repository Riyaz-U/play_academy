const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { setGlobalOptions } = require('firebase-functions/v2');
const admin = require('firebase-admin');
const Razorpay = require('razorpay');
const crypto = require('crypto');

admin.initializeApp();
const db = admin.firestore();

// Set default region (change to your preferred region)
setGlobalOptions({ region: 'asia-south2' });

// ─────────────────────────────────────────────────────────────────────────────
// 1. FCM: Notify players when a new session is created
// ─────────────────────────────────────────────────────────────────────────────
exports.onSessionCreated = onDocumentCreated(
  'sessions/{sessionId}',
  async (event) => {
    const session = event.data.data();
    if (!session) return;

    const { title, type, dateTime, location, branchId, category } = session;

    const sessionDate = dateTime.toDate
      ? dateTime.toDate().toLocaleDateString('en-IN', {
          weekday: 'short',
          day: 'numeric',
          month: 'short',
        })
      : 'Upcoming';

    const typeLabel = type === 'match' ? 'Match' : 'Training';
    const notificationTitle = `New ${typeLabel} Session Scheduled`;
    const notificationBody = `${title} on ${sessionDate}${location ? ' at ' + location : ''}`;

    // Collect FCM tokens: all players in this branch (optionally filtered by category)
    let query = db
      .collection('users')
      .where('branchId', '==', branchId)
      .where('role', '==', 'player');

    const snapshot = await query.get();
    if (snapshot.empty) return;

    const tokens = [];
    snapshot.forEach((doc) => {
      const data = doc.data();
      // If session has a category, only notify players of that category
      if (category && data.category && data.category !== category) return;
      if (data.fcmToken) tokens.push(data.fcmToken);
    });

    if (tokens.length === 0) return;

    // Send in batches of 500 (FCM limit)
    const batchSize = 500;
    const batches = [];
    for (let i = 0; i < tokens.length; i += batchSize) {
      batches.push(tokens.slice(i, i + batchSize));
    }

    for (const batch of batches) {
      const message = {
        tokens: batch,
        notification: {
          title: notificationTitle,
          body: notificationBody,
        },
        data: {
          sessionId: event.params.sessionId,
          type: type,
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          notification: {
            channelId: 'play_academy_channel',
            priority: 'high',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
            },
          },
        },
      };

      try {
        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(
          `FCM sent: ${response.successCount} success, ${response.failureCount} failure`
        );
      } catch (err) {
        console.error('FCM error:', err);
      }
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────────
// 2. Razorpay: Create order
// ─────────────────────────────────────────────────────────────────────────────
exports.createRazorpayOrder = onCall(async (request) => {
  // Ensure user is authenticated
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be logged in.');
  }

  const { paymentDocId } = request.data;
  if (!paymentDocId) {
    throw new HttpsError('invalid-argument', 'paymentDocId is required.');
  }

  // Fetch payment document
  const paymentRef = db.collection('payments').doc(paymentDocId);
  const paymentDoc = await paymentRef.get();
  if (!paymentDoc.exists) {
    throw new HttpsError('not-found', 'Payment not found.');
  }

  const payment = paymentDoc.data();

  // Only allow the player who owns this payment
  if (payment.playerId !== request.auth.uid) {
    throw new HttpsError('permission-denied', 'Not authorized.');
  }

  if (payment.status === 'paid') {
    throw new HttpsError('already-exists', 'Payment already completed.');
  }

  // Read Razorpay credentials from environment config
  // Set these with: firebase functions:secrets:set RAZORPAY_KEY_ID
  const keyId = process.env.RAZORPAY_KEY_ID;
  const keySecret = process.env.RAZORPAY_KEY_SECRET;

  if (!keyId || !keySecret) {
    throw new HttpsError(
      'internal',
      'Razorpay credentials not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET secrets.'
    );
  }

  const razorpay = new Razorpay({ key_id: keyId, key_secret: keySecret });

  // Amount in paise (INR × 100)
  const amountPaise = Math.round(payment.amount * 100);

  const order = await razorpay.orders.create({
    amount: amountPaise,
    currency: 'INR',
    receipt: paymentDocId,
    notes: {
      playerId: payment.playerId,
      playerName: payment.playerName,
      description: payment.description,
    },
  });

  // Store orderId in payment document
  await paymentRef.update({ razorpayOrderId: order.id });

  return {
    orderId: order.id,
    amount: order.amount,
    currency: order.currency,
    keyId: keyId,
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. Razorpay: Verify payment signature and mark as paid
// ─────────────────────────────────────────────────────────────────────────────
exports.verifyRazorpayPayment = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Must be logged in.');
  }

  const { paymentDocId, razorpayOrderId, razorpayPaymentId, razorpaySignature } =
    request.data;

  if (!paymentDocId || !razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
    throw new HttpsError('invalid-argument', 'Missing required payment fields.');
  }

  const keySecret = process.env.RAZORPAY_KEY_SECRET;
  if (!keySecret) {
    throw new HttpsError('internal', 'Razorpay key secret not configured.');
  }

  // Verify signature: HMAC-SHA256 of "orderId|paymentId" with key secret
  const body = `${razorpayOrderId}|${razorpayPaymentId}`;
  const expectedSignature = crypto
    .createHmac('sha256', keySecret)
    .update(body)
    .digest('hex');

  if (expectedSignature !== razorpaySignature) {
    throw new HttpsError('invalid-argument', 'Payment signature verification failed.');
  }

  // Update Firestore payment record
  const paymentRef = db.collection('payments').doc(paymentDocId);
  const paymentDoc = await paymentRef.get();
  if (!paymentDoc.exists) {
    throw new HttpsError('not-found', 'Payment not found.');
  }

  const payment = paymentDoc.data();
  if (payment.playerId !== request.auth.uid) {
    throw new HttpsError('permission-denied', 'Not authorized.');
  }

  await paymentRef.update({
    status: 'paid',
    razorpayPaymentId: razorpayPaymentId,
    razorpaySignature: razorpaySignature,
    paidAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
});
