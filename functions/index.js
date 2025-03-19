const {onValueUpdated} = require("firebase-functions/v2/database");
const admin = require('firebase-admin');
admin.initializeApp();

const firestore = admin.firestore();

exports.onUserStateChange = onValueUpdated('/{uid}/active', async (event) => {
    const isActive = event.data.after.val();
    const uid = event.params.uid;
    const firestoreRef = firestore.doc(`users/${uid}`);

    return firestoreRef.update({
        active: isActive,
        lastSeen: Date.now(),
    });
});
