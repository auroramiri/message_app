import { onValueUpdated } from 'firebase-functions/v2/database';
import { firestore } from './firebase.js';

export const lastSeenStatus = onValueUpdated('/{uid}/active', async (event) => {
  const isActive = event.data.after.val();
  const uid = event.params.uid;
  const firestoreRef = firestore.doc(`users/${uid}`);

  return firestoreRef.update({
    active: isActive,
    lastSeen: Date.now(),
  });
});
