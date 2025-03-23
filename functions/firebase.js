import { initializeApp } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import { getMessaging } from 'firebase-admin/messaging';

// Инициализация Firebase Admin SDK
initializeApp();

const firestore = getFirestore();
const messaging = getMessaging();

export { firestore, messaging };
