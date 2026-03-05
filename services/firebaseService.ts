import { db } from '../firebase';
import { 
  collection, 
  addDoc, 
  getDocs, 
  deleteDoc, 
  doc, 
  setDoc, 
  getDoc,
  query,
  orderBy,
  Timestamp
} from 'firebase/firestore';
import { Quote, ScheduledTime, JournalEntry, SoundscapeData, BreathingAudioData } from '../types';
import { DEFAULT_SOUNDSCAPES, DEFAULT_BREATHING_AUDIO } from '../constants';

const QUOTES_COLLECTION = 'quotes';
const JOURNALS_COLLECTION = 'journals';
const SETTINGS_COLLECTION = 'settings';
const SOUNDSCAPES_COLLECTION = 'soundscapes';
const USERS_COLLECTION = 'users';
const TIME_DOC_ID = 'scheduledTime';
const BREATHING_DOC_ID = 'breathing';

// Local Storage Keys
const LS_QUOTES = 'healing_moments_quotes';
const LS_JOURNALS = 'healing_moments_journals';
const LS_TIME = 'healing_moments_time';

export const firebaseService = {
  // Personal Message
  async getPersonalMessage(userId: string): Promise<string> {
    if (!db) return '';
    try {
      const docRef = doc(db, USERS_COLLECTION, userId);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        return docSnap.data().message || '';
      }
      return '';
    } catch (error) {
      console.error('Error fetching personal message:', error);
      return '';
    }
  },

  async savePersonalMessage(userId: string, message: string): Promise<void> {
    if (!db) return;
    try {
      await setDoc(doc(db, USERS_COLLECTION, userId), { message }, { merge: true });
    } catch (error) {
      console.error('Error saving personal message:', error);
      throw error;
    }
  },

  // Soundscapes
  async getSoundscapes(): Promise<SoundscapeData[]> {
    if (!db) {
      console.warn('Firebase not initialized, falling back to defaults');
      return DEFAULT_SOUNDSCAPES;
    }
    try {
      const q = query(collection(db, SOUNDSCAPES_COLLECTION), orderBy('name'));
      const snapshot = await getDocs(q);
      if (snapshot.empty) {
        return DEFAULT_SOUNDSCAPES;
      }
      return snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      } as SoundscapeData));
    } catch (error) {
      console.warn('Firebase error (getSoundscapes), falling back to defaults:', error);
      return DEFAULT_SOUNDSCAPES;
    }
  },

  // Breathing Audio
  async getBreathingAudio(): Promise<BreathingAudioData> {
    if (!db) {
      console.warn('Firebase not initialized, falling back to defaults');
      return DEFAULT_BREATHING_AUDIO;
    }
    try {
      const docRef = doc(db, SETTINGS_COLLECTION, BREATHING_DOC_ID);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        return docSnap.data() as BreathingAudioData;
      }
      return DEFAULT_BREATHING_AUDIO;
    } catch (error) {
      console.warn('Firebase error (getBreathingAudio), falling back to defaults:', error);
      return DEFAULT_BREATHING_AUDIO;
    }
  },

  // Initialize Data
  async initializeFirestoreData(): Promise<void> {
    // Always initialize Local Storage defaults first
    console.log('Initializing Local Storage defaults...');
    if (!localStorage.getItem(LS_QUOTES)) {
      localStorage.setItem(LS_QUOTES, JSON.stringify([{
        id: 'default-1',
        text: "오늘 하루도 정말 고생 많았어요. 당신은 충분히 잘하고 있습니다."
      }]));
    }
    localStorage.setItem(LS_TIME, JSON.stringify({ hours: 21, minutes: 0 }));

    if (!db) {
      console.warn('Firebase not initialized, only Local Storage was set up.');
      return;
    }

    try {
      console.log('Starting Firestore database initialization...');
      // Initialize Soundscapes
      const soundscapesRef = collection(db, SOUNDSCAPES_COLLECTION);
      for (const sound of DEFAULT_SOUNDSCAPES) {
        await setDoc(doc(soundscapesRef, sound.id), sound);
      }

      // Initialize Breathing Audio
      await setDoc(doc(db, SETTINGS_COLLECTION, BREATHING_DOC_ID), DEFAULT_BREATHING_AUDIO);

      // Initialize a sample quote if none exist
      const quotesRef = collection(db, QUOTES_COLLECTION);
      const quotesSnap = await getDocs(quotesRef);
      if (quotesSnap.empty) {
        await addDoc(quotesRef, {
          text: "오늘 하루도 정말 고생 많았어요. 당신은 충분히 잘하고 있습니다.",
          createdAt: Timestamp.now()
        });
      }

      console.log('Firestore database initialized with default data');
    } catch (error) {
      console.error('Error initializing Firestore data:', error);
      throw error;
    }
  },

  // Quotes
  async getQuotes(): Promise<Quote[]> {
    if (!db) {
      console.warn('Firebase not initialized, falling back to localStorage');
      const localData = localStorage.getItem(LS_QUOTES);
      return localData ? JSON.parse(localData) : [];
    }
    try {
      const q = query(collection(db, QUOTES_COLLECTION), orderBy('createdAt', 'desc'));
      const snapshot = await getDocs(q);
      return snapshot.docs.map(doc => ({
        id: doc.id,
        text: doc.data().text,
      } as Quote));
    } catch (error) {
      console.warn('Firebase error (getQuotes), falling back to localStorage:', error);
      const localData = localStorage.getItem(LS_QUOTES);
      return localData ? JSON.parse(localData) : [];
    }
  },

  async addQuote(text: string): Promise<Quote> {
    if (!db) {
      console.warn('Firebase not initialized, falling back to localStorage');
      const localData = localStorage.getItem(LS_QUOTES);
      const quotes: Quote[] = localData ? JSON.parse(localData) : [];
      const newQuote: Quote = { id: Date.now().toString(), text };
      localStorage.setItem(LS_QUOTES, JSON.stringify([newQuote, ...quotes]));
      return newQuote;
    }
    try {
      const docRef = await addDoc(collection(db, QUOTES_COLLECTION), {
        text,
        createdAt: Timestamp.now()
      });
      return { id: docRef.id, text };
    } catch (error) {
      console.warn('Firebase error (addQuote), falling back to localStorage:', error);
      const localData = localStorage.getItem(LS_QUOTES);
      const quotes: Quote[] = localData ? JSON.parse(localData) : [];
      const newQuote: Quote = { id: Date.now().toString(), text };
      localStorage.setItem(LS_QUOTES, JSON.stringify([newQuote, ...quotes]));
      return newQuote;
    }
  },

  async deleteQuote(id: string): Promise<void> {
    if (!db) {
      console.warn('Firebase not initialized, falling back to localStorage');
      const localData = localStorage.getItem(LS_QUOTES);
      if (localData) {
        const quotes: Quote[] = JSON.parse(localData);
        const filtered = quotes.filter(q => q.id !== id);
        localStorage.setItem(LS_QUOTES, JSON.stringify(filtered));
      }
      return;
    }
    try {
      await deleteDoc(doc(db, QUOTES_COLLECTION, id));
    } catch (error) {
      console.warn('Firebase error (deleteQuote), falling back to localStorage:', error);
      const localData = localStorage.getItem(LS_QUOTES);
      if (localData) {
        const quotes: Quote[] = JSON.parse(localData);
        const filtered = quotes.filter(q => q.id !== id);
        localStorage.setItem(LS_QUOTES, JSON.stringify(filtered));
      }
    }
  },

  // Scheduled Time
  async getScheduledTime(): Promise<ScheduledTime | null> {
    if (!db) {
      console.warn('Firebase not initialized, falling back to localStorage');
      const localData = localStorage.getItem(LS_TIME);
      return localData ? JSON.parse(localData) : null;
    }
    try {
      const docRef = doc(db, SETTINGS_COLLECTION, TIME_DOC_ID);
      const docSnap = await getDoc(docRef);
      if (docSnap.exists()) {
        return docSnap.data() as ScheduledTime;
      }
      return null;
    } catch (error) {
      console.warn('Firebase error (getScheduledTime), falling back to localStorage:', error);
      const localData = localStorage.getItem(LS_TIME);
      return localData ? JSON.parse(localData) : null;
    }
  },

  async saveScheduledTime(time: ScheduledTime): Promise<ScheduledTime> {
    if (!db) {
      console.warn('Firebase not initialized, falling back to localStorage');
      localStorage.setItem(LS_TIME, JSON.stringify(time));
      return time;
    }
    try {
      await setDoc(doc(db, SETTINGS_COLLECTION, TIME_DOC_ID), time);
      return time;
    } catch (error) {
      console.warn('Firebase error (saveScheduledTime), falling back to localStorage:', error);
      localStorage.setItem(LS_TIME, JSON.stringify(time));
      return time;
    }
  },

  // Journals
  async getJournals(userId?: string): Promise<JournalEntry[]> {
    if (!db) {
      console.warn('Firebase not initialized, falling back to localStorage');
      const localData = localStorage.getItem(LS_JOURNALS);
      return localData ? JSON.parse(localData) : [];
    }
    try {
      // 1. Fetch public journals
      const q = query(collection(db, JOURNALS_COLLECTION), orderBy('date', 'desc'));
      const snapshot = await getDocs(q);
      const publicJournals = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
        isPrivate: false
      } as JournalEntry));

      // 2. Fetch private journals if userId is provided
      let privateJournals: JournalEntry[] = [];
      if (userId) {
        const userJournalsRef = collection(db, USERS_COLLECTION, userId, 'journals');
        const userJournalsQuery = query(userJournalsRef, orderBy('date', 'desc'));
        const userJournalsSnap = await getDocs(userJournalsQuery);
        privateJournals = userJournalsSnap.docs.map(doc => ({
          id: doc.id,
          ...doc.data(),
          isPrivate: true
        } as JournalEntry));
      }

      // 3. Merge and sort by date
      const allJournals = [...publicJournals, ...privateJournals].sort((a, b) => 
        new Date(b.date).getTime() - new Date(a.date).getTime()
      );

      return allJournals;
    } catch (error) {
      console.warn('Firebase error (getJournals), falling back to localStorage:', error);
      const localData = localStorage.getItem(LS_JOURNALS);
      return localData ? JSON.parse(localData) : [];
    }
  },

  async addJournal(text: string, aiReply: string, isPrivate: boolean = false, userId?: string): Promise<JournalEntry> {
    const date = new Date().toISOString();
    
    // Offline / Local Storage Fallback
    if (!db) {
      console.warn('Firebase not initialized, falling back to localStorage');
      const localData = localStorage.getItem(LS_JOURNALS);
      const journals: JournalEntry[] = localData ? JSON.parse(localData) : [];
      const newEntry: JournalEntry = { id: Date.now().toString(), text, aiReply, date, isPrivate };
      localStorage.setItem(LS_JOURNALS, JSON.stringify([newEntry, ...journals]));
      return newEntry;
    }

    try {
      let docRef;
      if (isPrivate && userId) {
        // Save to users/{userId}/journals
        docRef = await addDoc(collection(db, USERS_COLLECTION, userId, 'journals'), {
          text,
          aiReply,
          date,
          createdAt: Timestamp.now(),
          isPrivate: true
        });
      } else {
        // Save to public journals collection
        docRef = await addDoc(collection(db, JOURNALS_COLLECTION), {
          text,
          aiReply,
          date,
          createdAt: Timestamp.now(),
          isPrivate: false
        });
      }
      
      return { id: docRef.id, text, aiReply, date, isPrivate };
    } catch (error) {
      console.warn('Firebase error (addJournal), falling back to localStorage:', error);
      const localData = localStorage.getItem(LS_JOURNALS);
      const journals: JournalEntry[] = localData ? JSON.parse(localData) : [];
      const newEntry: JournalEntry = { id: Date.now().toString(), text, aiReply, date, isPrivate };
      localStorage.setItem(LS_JOURNALS, JSON.stringify([newEntry, ...journals]));
      return newEntry;
    }
  }
};
