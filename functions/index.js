const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getMessaging } = require('firebase-admin/messaging');
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');

initializeApp();
const db = getFirestore();

exports.notifyTurnEnding = onDocumentUpdated('rooms/{roomId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!after || after.status !== 'active' || after.timeLeft !== 10 || before.timeLeft === 10) return;

  const players = await event.data.after.ref.collection('players').get();
  const tokens = [];
  for (const player of players.docs) {
    const tokenDocs = await db.collection('users').doc(player.id).collection('fcmTokens').get();
    tokenDocs.forEach((token) => tokens.push(token.id));
  }
  if (tokens.length === 0) return;

  await getMessaging().sendEachForMulticast({
    tokens,
    notification: {
      title: 'Kroki',
      body: 'Plus que 10 secondes pour trouver le mot !',
    },
    data: { roomCode: event.params.roomId, type: 'turn_ending' },
  });
});

exports.rotateSeason = onSchedule({ schedule: '0 0 1 1,4,7,10 *', timeZone: 'UTC' }, async () => {
  const now = new Date();
  const quarter = Math.floor(now.getUTCMonth() / 3) + 1;
  const seasonId = `${now.getUTCFullYear()}-S${quarter}`;
  await db.collection('seasons').doc(seasonId).set({
    id: seasonId,
    status: 'active',
    startedAt: FieldValue.serverTimestamp(),
  }, { merge: true });
});
