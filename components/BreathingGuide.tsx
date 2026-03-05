import React, { useState, useEffect } from 'react';
import ReactPlayer from 'react-player';
import { motion, AnimatePresence } from 'framer-motion';
import { Wind, Play, Pause, RotateCcw } from 'lucide-react';
import { firebaseService } from '../services/firebaseService';
import { DEFAULT_BREATHING_AUDIO } from '../constants';
import VolumeSlider from './VolumeSlider';

const BreathingGuide: React.FC = () => {
  const [phase, setPhase] = useState<'inhale' | 'hold' | 'exhale' | 'idle'>('idle');
  const [seconds, setSeconds] = useState(0);
  const [isActive, setIsActive] = useState(false);
  const [isReady, setIsReady] = useState(false);
  const [audioUrl, setAudioUrl] = useState(DEFAULT_BREATHING_AUDIO.url);
  const [volume, setVolume] = useState(0.5);
  const [muted, setMuted] = useState(false);

  const Player = ReactPlayer as any;

  useEffect(() => {
    const fetchAudio = async () => {
      try {
        const data = await firebaseService.getBreathingAudio();
        if (data && data.url) {
          setAudioUrl(data.url);
        }
      } catch (error) {
        console.error('Failed to fetch breathing audio:', error);
      }
    };

    fetchAudio();
  }, []);

  useEffect(() => {
    let timer: NodeJS.Timeout;
    if (isActive) {
      const interval = setInterval(() => {
        setSeconds((prev) => prev + 1);
      }, 1000);
      return () => clearInterval(interval);
    }
    return () => {};
  }, [isActive]);

  useEffect(() => {
    if (!isActive) {
      setPhase('idle');
      return;
    }

    // 4-4-4 Box Breathing or similar
    const cycle = seconds % 12;
    if (cycle < 4) setPhase('inhale');
    else if (cycle < 8) setPhase('hold');
    else setPhase('exhale');
  }, [seconds, isActive]);

  const toggleBreathing = () => {
    setIsActive(!isActive);
    if (!isActive) {
      setSeconds(0);
    }
  };

  const reset = () => {
    setIsActive(false);
    setSeconds(0);
    setPhase('idle');
  };

  return (
    <div className="flex flex-col items-center justify-center gap-12 py-8">
      <div className="text-center">
        <h2 className="text-2xl font-bold mb-2">마이 콰이어트 타임</h2>
        <p className="text-gray-400 text-sm">단 1분이라도 온전히 나에게 집중해보세요.</p>
      </div>

      <div className="opacity-0 pointer-events-none absolute">
        <Player
          url={audioUrl}
          playing={isActive && isReady}
          loop={true}
          volume={muted ? 0 : volume}
          muted={muted}
          width="100%"
          height="100%"
          config={{
            file: {
              forceAudio: true,
              attributes: { preload: 'auto' }
            }
          }}
          onReady={() => setIsReady(true)}
          playsinline
        />
      </div>

      <div className="relative flex items-center justify-center">
        {/* Outer Glow */}
        <AnimatePresence>
          {isActive && (
            <motion.div
              initial={{ scale: 0.8, opacity: 0 }}
              animate={{ 
                scale: phase === 'inhale' ? 1.5 : phase === 'hold' ? 1.5 : 1,
                opacity: phase === 'inhale' ? 0.4 : phase === 'hold' ? 0.4 : 0.2
              }}
              transition={{ duration: 4, ease: "easeInOut" }}
              className="absolute w-64 h-64 rounded-full bg-pink-500/20 blur-3xl"
            />
          )}
        </AnimatePresence>

        {/* Breathing Circle */}
        <motion.div
          animate={{ 
            scale: phase === 'inhale' ? 1.2 : phase === 'hold' ? 1.2 : 1,
            borderColor: phase === 'inhale' ? 'rgba(244, 114, 182, 0.8)' : 'rgba(244, 114, 182, 0.3)'
          }}
          transition={{ duration: 4, ease: "easeInOut" }}
          className="w-60 h-60 rounded-full border-4 flex flex-col items-center justify-center z-10 bg-black/20 backdrop-blur-sm"
        >
          <Wind className={`w-12 h-12 mb-4 transition-colors duration-1000 ${phase === 'inhale' ? 'text-pink-400' : 'text-gray-500'}`} />
          <div className="text-xl font-medium capitalize tracking-widest">
            {phase === 'inhale' && '숨 들이마시기'}
            {phase === 'hold' && '잠시 멈추기'}
            {phase === 'exhale' && '숨 내뱉기'}
            {phase === 'idle' && '준비하기'}
          </div>
          {isActive && <div className="mt-2 text-sm text-gray-400">{Math.floor(seconds / 60)}:{(seconds % 60).toString().padStart(2, '0')}</div>}
        </motion.div>
      </div>

      <div className="flex gap-4">
        <button
          onClick={toggleBreathing}
          className="w-16 h-16 rounded-full bg-white/10 flex items-center justify-center hover:bg-white/20 transition-all active:scale-95"
        >
          {isActive ? <Pause className="w-6 h-6" /> : <Play className="w-6 h-6 ml-1" />}
        </button>
        <button
          onClick={reset}
          className="w-16 h-16 rounded-full bg-white/5 flex items-center justify-center hover:bg-white/10 transition-all active:scale-95"
        >
          <RotateCcw className="w-6 h-6" />
        </button>
      </div>

      <VolumeSlider 
        volume={volume}
        onVolumeChange={(v) => {
          setVolume(v);
          if (v > 0) setMuted(false);
        }}
        muted={muted}
        onMuteToggle={() => setMuted(!muted)}
        className="w-full max-w-xs"
      />
    </div>
  );
};

export default BreathingGuide;
