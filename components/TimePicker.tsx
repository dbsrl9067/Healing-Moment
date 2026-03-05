
import React, { useState, useEffect } from 'react';
import { ScheduledTime } from '../types';

interface TimePickerProps {
  initialTime: ScheduledTime;
  onSave: (time: ScheduledTime) => void;
}

const TimePicker: React.FC<TimePickerProps> = ({ initialTime, onSave }) => {
  const [hours, setHours] = useState(initialTime.hours);
  const [minutes, setMinutes] = useState(initialTime.minutes);

  const handleSave = () => {
    onSave({ hours, minutes });
  };

  return (
    <div className="bg-white/60 backdrop-blur-md p-8 rounded-3xl shadow-xl border border-pink-100 w-full max-w-sm">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-pink-600 mb-2">알림 시간 설정</h2>
        <p className="text-gray-500 text-sm">매일 이 시간에 응원 문구를 보내드릴게요.</p>
      </div>

      <div className="flex items-center justify-center gap-4 mb-8">
        <div className="flex flex-col items-center">
          <label className="text-xs text-gray-400 mb-1">시간</label>
          <select
            value={hours}
            onChange={(e) => setHours(parseInt(e.target.value))}
            className="text-4xl font-bold text-gray-700 bg-pink-50 rounded-xl px-4 py-3 appearance-none focus:outline-none focus:ring-2 focus:ring-pink-300 transition-all cursor-pointer"
          >
            {Array.from({ length: 24 }).map((_, i) => (
              <option key={i} value={i}>
                {i.toString().padStart(2, '0')}
              </option>
            ))}
          </select>
        </div>

        <span className="text-3xl font-bold text-pink-300 mt-4">:</span>

        <div className="flex flex-col items-center">
          <label className="text-xs text-gray-400 mb-1">분</label>
          <select
            value={minutes}
            onChange={(e) => setMinutes(parseInt(e.target.value))}
            className="text-4xl font-bold text-gray-700 bg-pink-50 rounded-xl px-4 py-3 appearance-none focus:outline-none focus:ring-2 focus:ring-pink-300 transition-all cursor-pointer"
          >
            {Array.from({ length: 60 }).map((_, i) => (
              <option key={i} value={i}>
                {i.toString().padStart(2, '0')}
              </option>
            ))}
          </select>
        </div>
      </div>

      <button
        onClick={handleSave}
        className="w-full bg-pink-400 hover:bg-pink-500 text-white font-bold py-4 rounded-2xl shadow-lg transition-all transform active:scale-95 flex items-center justify-center gap-2"
      >
        <i className="fa-solid fa-check"></i>
        저장하기
      </button>
    </div>
  );
};

export default TimePicker;
