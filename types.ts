
export interface ScheduledTime {
  hours: number;
  minutes: number;
}

export interface Quote {
  id: string | number;
  text: string;
}

export interface JournalEntry {
  id: string | number;
  date: string;
  text: string;
  aiReply: string;
  isPrivate?: boolean;
}

export interface SoundscapeData {
  id: string;
  name: string;
  iconName: string;
  url: string;
  color: string;
}

export interface BreathingAudioData {
  url: string;
}

export enum AppState {
  LOADING = 'LOADING',
  IDLE = 'IDLE',
  SUCCESS = 'SUCCESS',
  ERROR = 'ERROR'
}
