import React, { useEffect } from 'react';
import ReactPlayer from 'react-player';
import { Play, Pause, CloudRain, Flame, Waves, Coffee, Library, Music } from 'lucide-react';
import { useSound } from '../context/SoundContext';
import VolumeSlider from './VolumeSlider';

const getIcon = (iconName: string) => {
  switch (iconName) {
    case 'library': return <Library className="w-6 h-6" />;
    case 'flame': return <Flame className="w-6 h-6" />;
    case 'waves': return <Waves className="w-6 h-6" />;
    case 'coffee': return <Coffee className="w-6 h-6" />;
    case 'cloudRain': return <CloudRain className="w-6 h-6" />;
    default: return <Music className="w-6 h-6" />;
  }
};

const Soundscape: React.FC = () => {
  const { 
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
  } = useSound();

  const Player = ReactPlayer as any;

  return (
    <div className="flex flex-col gap-8 py-8">
      <div className="text-center">
        <h2 className="text-2xl font-bold mb-2">ASMR 사운드스케이프</h2>
        <p className="text-gray-400 text-sm">공간의 입체감을 살린 고품질 오디오 컨텐츠입니다.</p>
        {playingId && !isReady && !errorId && (
          <p className="text-pink-400 text-xs mt-2 animate-pulse">음원을 불러오는 중입니다...</p>
        )}
        {errorId && (
          <p className="text-red-400 text-xs mt-2">오디오 재생 중 오류가 발생했습니다.</p>
        )}
      </div>

      {/* Active Player */}
      <div style={{ position: 'absolute', width: 0, height: 0, overflow: 'hidden', opacity: 0, pointerEvents: 'none' }}>
        {playingId && (() => {
          const activeSound = sounds.find(s => s.id === playingId);
          if (!activeSound) return null;
          
          return (
            <Player
              key={activeSound.id}
              url={activeSound.url}
              playing={true}
              volume={muted ? 0 : volume}
              muted={muted}
              loop={true}
              width="0"
              height="0"
              config={{
                file: {
                  forceAudio: true,
                  attributes: { preload: 'auto' }
                }
              }}
              onReady={() => setIsReady(true)}
              onError={(e: any) => {
                console.error(`Player error (${activeSound.name}):`, e);
                setErrorId(activeSound.id);
              }}
              playsinline
            />
          );
        })()}
      </div>

      <div className="grid grid-cols-1 gap-4">
        {sounds.map((sound) => (
          <button
            key={sound.id}
            onClick={() => toggleSound(sound)}
            className={`glass-card p-4 rounded-3xl flex items-center justify-between transition-all active:scale-[0.98] ${playingId === sound.id ? 'border-pink-500/50 bg-pink-500/10' : 'border-white/5'}`}
          >
            <div className="flex items-center gap-4">
              <div className={`w-12 h-12 rounded-2xl flex items-center justify-center ${sound.color} text-white shrink-0`}>
                {getIcon(sound.iconName)}
              </div>
              <div className="text-left min-w-0">
                <h3 className="font-bold text-base truncate">{sound.name}</h3>
                <p className="text-[10px] text-gray-500 uppercase tracking-widest mt-1 truncate">Ambient Soundscape</p>
              </div>
            </div>
            <div className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 ${playingId === sound.id ? 'bg-pink-500 text-white' : 'bg-white/5 text-gray-400'}`}>
              {playingId === sound.id ? <Pause className="w-4 h-4" /> : <Play className="w-4 h-4 ml-0.5" />}
            </div>
          </button>
        ))}
      </div>

      <VolumeSlider 
        volume={volume}
        onVolumeChange={(v) => {
          setVolume(v);
          if (v > 0) setMuted(false);
        }}
        muted={muted}
        onMuteToggle={() => setMuted(!muted)}
        className={playingId ? "animate-in slide-in-from-bottom-4 duration-500" : "opacity-50"}
      />
    </div>
  );
};

export default Soundscape;
