import React, { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { Send, Sparkles, Trash2, Calendar, MessageCircleHeart, Lock, Globe } from 'lucide-react';
import { GoogleGenAI } from "@google/genai";
import { firebaseService } from '../services/firebaseService';
import { JournalEntry } from '../types';
import { useAuth } from '../context/AuthContext';

const Journal: React.FC = () => {
  const [entries, setEntries] = useState<JournalEntry[]>([]);
  const [text, setText] = useState('');
  const [isGenerating, setIsGenerating] = useState(false);
  const [aiReply, setAiReply] = useState('');
  const [isPrivate, setIsPrivate] = useState(false);
  const { user } = useAuth();

  useEffect(() => {
    firebaseService.getJournals(user?.id).then(setEntries);
  }, [user]);

  const getAiComfort = async (content: string) => {
    setIsGenerating(true);
    try {
      const apiKey = process.env.GEMINI_API_KEY;
      if (!apiKey) {
        throw new Error("Gemini API Key is missing");
      }
      
      const ai = new GoogleGenAI({ apiKey });
      const response = await ai.models.generateContent({
        model: "gemini-3-flash-preview",
        contents: `당신은 따뜻하고 공감 능력이 뛰어난 심리 상담가입니다. 사용자가 오늘 하루의 감정을 기록했습니다. 
        사용자의 글에 깊이 공감해주고, 따뜻한 위로와 격려의 메시지를 3문장 내외로 작성해주세요. 
        또한 그 감정에 어울리는 짧은 시(Poem)나 명언을 하나 추천해주세요.
        
        사용자의 글: "${content}"`,
      });
      
      const reply = response.text || "당신의 마음을 온전히 이해합니다. 오늘 하루도 정말 고생 많으셨어요.";
      setAiReply(reply);
      return reply;
    } catch (error) {
      console.error('AI error:', error);
      return "따뜻한 위로를 전하고 싶었지만, 잠시 연결이 원활하지 않네요. 그래도 당신의 마음은 충분히 소중합니다.";
    } finally {
      setIsGenerating(false);
    }
  };

  const handleSave = async () => {
    if (!text.trim()) return;
    
    const reply = await getAiComfort(text);
    
    try {
      const newEntry = await firebaseService.addJournal(text, reply, isPrivate, user?.id);
      setEntries([newEntry, ...entries]);
      setText('');
      setAiReply('');
    } catch (error) {
      console.error('Save journal error:', error);
    }
  };

  const formatDate = (dateStr: string) => {
    const date = new Date(dateStr);
    return `${date.getMonth() + 1}월 ${date.getDate()}일 ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`;
  };

  return (
    <div className="flex flex-col gap-8 py-8">
      <div className="text-center">
        <h2 className="text-2xl font-bold mb-2">감정 기록 & 한 줄 확언</h2>
        <p className="text-gray-400 text-sm">그날의 '결정적 힐링 순간'을 기록해보세요.</p>
      </div>

      <div className="glass-card p-6 rounded-[2.5rem] flex flex-col gap-4">
        <textarea
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="오늘 나를 웃게 했던 짧은 순간이나 지금의 감정을 기록해보세요..."
          className="w-full h-32 bg-transparent border-none focus:ring-0 text-lg leading-relaxed resize-none text-white placeholder-white/20"
        />
        <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
          <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3 w-full sm:w-auto">
            {user && (
              <button
                onClick={() => setIsPrivate(!isPrivate)}
                className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-bold transition-all whitespace-nowrap ${isPrivate ? 'bg-purple-500/20 text-purple-300' : 'bg-white/5 text-gray-400'}`}
              >
                {isPrivate ? <Lock className="w-3.5 h-3.5" /> : <Globe className="w-3.5 h-3.5" />}
                {isPrivate ? '나만 보기 (소장)' : '공개 기록'}
              </button>
            )}
            <div className="flex items-center gap-2 text-xs text-gray-500 whitespace-nowrap">
              <Sparkles className="w-3.5 h-3.5 text-pink-400" />
              AI가 따뜻한 공감 답장을 준비합니다
            </div>
          </div>
          <button
            onClick={handleSave}
            disabled={!text.trim() || isGenerating}
            className={`w-full sm:w-auto px-6 py-3 rounded-2xl font-bold flex items-center justify-center gap-2 transition-all active:scale-95 whitespace-nowrap ${!text.trim() || isGenerating ? 'bg-white/5 text-gray-500' : 'bg-pink-500 text-white shadow-lg shadow-pink-500/20'}`}
          >
            {isGenerating ? <div className="animate-spin w-5 h-5 border-2 border-white/20 border-t-white rounded-full" /> : <Send className="w-5 h-5" />}
            기록하기
          </button>
        </div>
      </div>

      <div className="flex flex-col gap-6">
        <h3 className="text-lg font-bold flex items-center gap-2">
          <Calendar className="w-5 h-5 text-pink-400" />
          나의 힐링 조각들
        </h3>
        
        <div className="space-y-6">
          {entries.map((entry) => (
            <motion.div
              key={entry.id}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              className="glass-card p-6 rounded-[2rem] flex flex-col gap-4 border-white/5 relative overflow-hidden"
            >
              {entry.isPrivate && (
                <div className="absolute top-0 right-0 p-4">
                  <Lock className="w-4 h-4 text-purple-400/50" />
                </div>
              )}
              <div className="flex justify-between items-start">
                <span className="text-xs font-bold text-gray-500 uppercase tracking-widest">{formatDate(entry.date)}</span>
              </div>
              <p className="text-gray-200 leading-relaxed">{entry.text}</p>
              
              {entry.aiReply && (
                <div className="bg-pink-500/10 border border-pink-500/20 p-5 rounded-2xl flex flex-col gap-2">
                  <div className="flex items-center gap-2 text-pink-400 text-xs font-bold uppercase tracking-widest">
                    <MessageCircleHeart className="w-4 h-4" />
                    AI 공감 답장
                  </div>
                  <p className="text-sm text-pink-100/80 italic leading-relaxed whitespace-pre-wrap">
                    {entry.aiReply}
                  </p>
                </div>
              )}
            </motion.div>
          ))}
          
          {entries.length === 0 && (
            <div className="text-center py-12 text-gray-500">
              <p>아직 기록된 순간이 없네요.</p>
              <p className="text-sm mt-1">오늘의 작은 행복을 기록해보는 건 어떨까요?</p>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default Journal;
