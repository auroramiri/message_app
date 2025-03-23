import { firestore, messaging } from './firebase.js';
import { lastSeenStatus } from './lastSeenStatus.js';
import { sendNotification } from './sendNotification.js';

// Экспорт функций
export { lastSeenStatus, sendNotification };
