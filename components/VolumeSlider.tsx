import React from 'react';
import { Volume2, VolumeX, Volume1 } from 'lucide-react';

interface VolumeSliderProps {
  volume: number;
  onVolumeChange: (newVolume: number) => void;
  muted: boolean;
  onMuteToggle: () => void;
  className?: string;
}

const VolumeSlider: React.FC<VolumeSliderProps> = ({ 
  volume, 
  onVolumeChange, 
  muted, 
  onMuteToggle,
  className = "" 
}) => {
  const isIOS = /iPad|iPhone|iPod/.test(navigator.userAgent) && !(window as any).MSStream;

  return (
    <div className={`glass-card p-6 rounded-3xl flex flex-col gap-4 ${className}`}>
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <button 
            onClick={onMuteToggle}
            className="p-2 hover:bg-white/10 rounded-full transition-colors text-gray-400 hover:text-white"
          >
            {muted || volume === 0 ? (
              <VolumeX className="w-5 h-5" />
            ) : volume < 0.5 ? (
              <Volume1 className="w-5 h-5" />
            ) : (
              <Volume2 className="w-5 h-5" />
            )}
          </button>
          <span className="text-sm font-medium">볼륨 조절</span>
        </div>
        <span className="text-xs text-gray-500">{muted ? '0' : Math.round(volume * 100)}%</span>
      </div>
      
      <div className="relative flex items-center group">
        <input
          type="range"
          min="0"
          max="1"
          step="0.01"
          value={muted ? 0 : volume}
          onChange={(e) => onVolumeChange(parseFloat(e.target.value))}
          className="w-full h-1.5 bg-white/10 rounded-lg appearance-none cursor-pointer accent-pink-500 group-hover:bg-white/20 transition-all"
        />
      </div>

      {isIOS && (
        <p className="text-[10px] text-gray-500 text-center italic">
          iOS 기기에서는 기기 측면의 물리 버튼으로 볼륨을 조절해 주세요.
        </p>
      )}
    </div>
  );
};

export default VolumeSlider;
