
import React, { createContext, useContext, useState, useEffect } from 'react';
import { SoundscapeData } from '../types';
import { DEFAULT_SOUNDSCAPES } from '../constants';
import { firebaseService } from '../services/firebaseService';

interface SoundContextType {
  sounds: SoundscapeData[];
  playingId: string | null;
  volume: number;
  muted: boolean;
  isReady: boolean;
  errorId: string | null;
  toggleSound: (sound: SoundscapeData) => void;
  setVolume: (v: number) => void;
  setMuted: (m: boolean) => void;
  setIsReady: (r: boolean) => void;
  setErrorId: (id: string | null) => void;
}

const SoundContext = createContext<SoundContextType | undefined>(undefined);

export const SoundProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [sounds, setSounds] = useState<SoundscapeData[]>(DEFAULT_SOUNDSCAPES);
  const [playingId, setPlayingId] = useState<string | null>(null);
  const [volume, setVolume] = useState(0.5);
  const [muted, setMuted] = useState(false);
  const [isReady, setIsReady] = useState(false);
  const [errorId, setErrorId] = useState<string | null>(null);

  useEffect(() => {
    const fetchSounds = async () => {
      try {
        const data = await firebaseService.getSoundscapes();
        if (data && data.length > 0) {
          setSounds(data);
        }
      } catch (error) {
        console.error('Failed to fetch soundscapes:', error);
      }
    };
    fetchSounds();
  }, []);

  const toggleSound = (sound: SoundscapeData) => {
    setErrorId(null);
    if (playingId === sound.id) {
      setPlayingId(null);
    } else {
      setPlayingId(sound.id);
      setIsReady(false); // Reset ready state for new sound
    }
  };

  return (
    <SoundContext.Provider value={{
      sounds,
      playingId,
      volume,
      muted,
      isReady,
      errorId,
      toggleSound,
      setVolume,
      setMuted,
      setIsReady,
      setErrorId
    }}>
      {children}
    </SoundContext.Provider>
  );
};

export const useSound = () => {
  const context = useContext(SoundContext);
  if (context === undefined) {
    throw new Error('useSound must be used within a SoundProvider');
  }
  return context;
};
