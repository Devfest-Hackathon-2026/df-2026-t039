import {
  applicationDefault,
  initializeApp,
} from 'firebase-admin/app'
import { getAuth } from 'firebase-admin/auth'

const projectId = process.env.FIREBASE_PROJECT_ID

if (!projectId) {
  throw new Error('FIREBASE_PROJECT_IDが設定されていません')
}

const firebaseApp = initializeApp({
  credential: applicationDefault(),
  projectId,
})

export const firebaseAuth = getAuth(firebaseApp)