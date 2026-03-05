
import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Home, 
  Wind, 
  Music, 
  BookHeart, 
  Settings, 
  Bell, 
  Quote as QuoteIcon, 
  X,
  Heart,
  LogIn,
  LogOut,
  User,
  Edit2,
  Save,
  RotateCcw,
  Download
} from 'lucide-react';
import { db } from './firebase';
import { ScheduledTime, AppState, Quote } from './types';
import { HEALING_QUOTES } from './constants';
import { notificationService } from './services/notificationService';
import { firebaseService } from './services/firebaseService';
import TimePicker from './components/TimePicker';
import BreathingGuide from './components/BreathingGuide';
import Soundscape from './components/Soundscape';
import Journal from './components/Journal';
import { useAuth } from './context/AuthContext';
import { SoundProvider } from './context/SoundContext';
import AuthModal from './components/AuthModal';

type View = 'home' | 'breathe' | 'sound' | 'journal';

const App: React.FC = () => {
  const [currentView, setCurrentView] = useState<View>('home');
  const [scheduledTime, setScheduledTime] = useState<ScheduledTime | null>(null);
  const [quotes, setQuotes] = useState<Quote[]>([]);
  const [appState, setAppState] = useState<AppState>(AppState.LOADING);
  const [permissionGranted, setPermissionGranted] = useState<boolean>(false);
  const [currentQuote, setCurrentQuote] = useState<Quote | null>(null);
  const [isTimePickerOpen, setIsTimePickerOpen] = useState(false);
  const [isQuoteManagerOpen, setIsQuoteManagerOpen] = useState(false);
  const [isSettingsOpen, setIsSettingsOpen] = useState(false);
  const [isInitializing, setIsInitializing] = useState(false);
  const [showSetupBanner, setShowSetupBanner] = useState(false);
  const [newQuoteText, setNewQuoteText] = useState('');
  
  // Auth & Personal Message States
  const { user, logout } = useAuth();
  const [isAuthModalOpen, setIsAuthModalOpen] = useState(false);
  const [personalMessage, setPersonalMessage] = useState('');
  const [isEditingMessage, setIsEditingMessage] = useState(false);
  const [tempMessage, setTempMessage] = useState('');
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);

  // 초기 데이터 로드 및 권한 요청
  useEffect(() => {
    const handleBeforeInstallPrompt = (e: any) => {
      e.preventDefault();
      setDeferredPrompt(e);
    };

    window.addEventListener('beforeinstallprompt', handleBeforeInstallPrompt);

    const fetchData = async () => {
      try {
        // 권한 요청
        const granted = await notificationService.requestPermission();
        setPermissionGranted(granted);

        // 시간 로드
        const timeData = await firebaseService.getScheduledTime();
        setScheduledTime(timeData);

        // 문구 로드
        const quotesData = await firebaseService.getQuotes();
        setQuotes(quotesData);
        
        // Check if soundscapes exist in Firebase
        if (user?.role === 'admin') {
          const soundscapes = await firebaseService.getSoundscapes();
          // If it's returning defaults because Firebase is empty, show banner
          // Note: getSoundscapes returns DEFAULT_SOUNDSCAPES if empty
          // We need a way to know if it's actually from Firebase or not.
          // For now, let's just check if the user is admin and we want to encourage setup.
          setShowSetupBanner(true);
        }

        const quotesSource = quotesData.length > 0 ? quotesData : HEALING_QUOTES;
        const randomIndex = Math.floor(Math.random() * quotesSource.length);
        setCurrentQuote(quotesSource[randomIndex]);
        
        setAppState(AppState.IDLE);
      } catch (error) {
        console.error('Data fetch error:', error);
        setAppState(AppState.ERROR);
      }
    };

    fetchData();
  }, [user]);

  // Fetch personal message when user logs in
  useEffect(() => {
    const fetchMessage = async () => {
      if (user) {
        try {
          const message = await firebaseService.getPersonalMessage(user.id);
          setPersonalMessage(message);
          setTempMessage(message);
        } catch (err) {
          console.error('Failed to fetch message:', err);
        }
      } else {
        setPersonalMessage('');
        setTempMessage('');
      }
    };
    fetchMessage();
  }, [user]);

  const handleSaveMessage = async () => {
    if (!user) return;
    try {
      await firebaseService.savePersonalMessage(user.id, tempMessage);
      setPersonalMessage(tempMessage);
      setIsEditingMessage(false);
    } catch (error) {
      console.error('Failed to save message:', error);
    }
  };

  // 알림 스케줄링
  useEffect(() => {
    if (!scheduledTime || !permissionGranted) return;

    const interval = setInterval(() => {
      const now = new Date();
      if (now.getHours() === scheduledTime.hours && now.getMinutes() === scheduledTime.minutes && now.getSeconds() === 0) {
        notificationService.showRandomQuote(quotes);
      }
    }, 1000);

    return () => clearInterval(interval);
  }, [scheduledTime, permissionGranted, quotes]);

  const handleSaveTime = async (time: ScheduledTime) => {
    try {
      const data = await firebaseService.saveScheduledTime(time);
      setScheduledTime(data);
      setIsTimePickerOpen(false);
      
      setAppState(AppState.SUCCESS);
      setTimeout(() => setAppState(AppState.IDLE), 2000);
    } catch (error) {
      console.error('Save time error:', error);
    }
  };

  const handleAddQuote = async () => {
    if (!newQuoteText.trim()) return;
    
    try {
      const newQuote = await firebaseService.addQuote(newQuoteText.trim());
      
      const updatedQuotes = [newQuote, ...quotes];
      setQuotes(updatedQuotes);
      setNewQuoteText('');
    } catch (error) {
      console.error('Add quote error:', error);
    }
  };

  const handleDeleteQuote = async (id: string | number) => {
    try {
      await firebaseService.deleteQuote(id.toString());
      
      const updatedQuotes = quotes.filter(q => q.id !== id);
      setQuotes(updatedQuotes);
      
      if (currentQuote?.id === id) {
        if (updatedQuotes.length > 0) {
          setCurrentQuote(updatedQuotes[0]);
        } else {
          setCurrentQuote(null);
        }
      }
    } catch (error) {
      console.error('Delete quote error:', error);
    }
  };

  const handleInitialize = async () => {
    const isOffline = !db;
    const confirmMsg = isOffline 
      ? 'Firebase가 연결되지 않았습니다. 로컬 저장소에 기본 데이터를 생성하시겠습니까?'
      : '데이터베이스를 초기화하시겠습니까? 기본 데이터가 생성됩니다.';
    
    if (!window.confirm(confirmMsg)) return;
    setIsInitializing(true);
    try {
      await firebaseService.initializeFirestoreData();
      setShowSetupBanner(false);
      setAppState(AppState.SUCCESS);
      setTimeout(() => setAppState(AppState.IDLE), 2000);
      // Reload page to reflect changes
      window.location.reload();
    } catch (error) {
      console.error('Initialization error:', error);
      alert('초기화 중 오류가 발생했습니다.');
    } finally {
      setIsInitializing(false);
    }
  };

  const handleInstallApp = async () => {
    if (!deferredPrompt) return;
    deferredPrompt.prompt();
    const { outcome } = await deferredPrompt.userChoice;
    if (outcome === 'accepted') {
      setDeferredPrompt(null);
    }
  };

  const formatTime = (time: ScheduledTime) => {
    const period = time.hours >= 12 ? '오후' : '오전';
    const h = time.hours % 12 || 12;
    const m = time.minutes.toString().padStart(2, '0');
    return `${period} ${h}:${m}`;
  };

  if (appState === AppState.LOADING) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#0a0502]">
        <motion.div 
          animate={{ opacity: [0.4, 1, 0.4] }}
          transition={{ duration: 2, repeat: Infinity }}
          className="text-pink-400 text-xl font-medium tracking-widest uppercase"
        >
          Healing Moments
        </motion.div>
      </div>
    );
  }

  return (
    <SoundProvider>
      <div className="h-screen w-full bg-[#0a0502] text-white font-sans selection:bg-pink-500/30 overflow-hidden flex justify-center">
        <div className="atmosphere" />

        <main className="relative z-10 w-full max-w-lg md:max-w-2xl h-full flex flex-col shadow-2xl transition-all duration-300">
          <div className="flex-1 overflow-y-auto px-4 pt-12 pb-32 [&::-webkit-scrollbar]:hidden" style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' }}>
          
          {/* Top Header */}
          <header className="flex justify-between items-center mb-12">
            <div className="flex items-center gap-3">
              <div className="p-2 bg-white/10 rounded-xl">
                <Heart className="w-6 h-6 text-pink-400" />
              </div>
              <h1 className="text-xl font-bold tracking-tight">힐링 모먼트</h1>
            </div>
            <div className="flex gap-2">
              {user ? (
                <button 
                  onClick={logout}
                  className="p-3 bg-white/5 hover:bg-white/10 rounded-2xl transition-all active:scale-95 text-gray-400 hover:text-white"
                  title="로그아웃"
                >
                  <LogOut className="w-6 h-6" />
                </button>
              ) : (
                <button 
                  onClick={() => setIsAuthModalOpen(true)}
                  className="p-3 bg-pink-500/10 hover:bg-pink-500/20 rounded-2xl transition-all active:scale-95 text-pink-400"
                  title="로그인"
                >
                  <LogIn className="w-6 h-6" />
                </button>
              )}
              <button 
                onClick={() => setIsSettingsOpen(true)}
                className="p-3 bg-white/5 hover:bg-white/10 rounded-2xl transition-all active:scale-95"
              >
                <Settings className="w-6 h-6 text-gray-400" />
              </button>
            </div>
          </header>

          {/* Content View */}
          <AnimatePresence mode="wait">
            <motion.div
              key={currentView}
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.3 }}
              className="flex-grow"
            >
              {currentView === 'home' && (
                <div className="flex flex-col gap-8">
                  {/* Personal Message Section */}
                  {user && (
                    <div className="glass-card p-6 rounded-[2rem] relative overflow-hidden group">
                      <div className="flex items-center justify-between mb-4">
                        <div className="flex items-center gap-2">
                          <User className="w-5 h-5 text-pink-400" />
                          <span className="text-sm font-bold text-gray-300">{user.username}님을 위한 응원</span>
                        </div>
                        <button 
                          onClick={() => {
                            if (isEditingMessage) handleSaveMessage();
                            else setIsEditingMessage(true);
                          }}
                          className="p-2 hover:bg-white/10 rounded-full transition-colors text-gray-400 hover:text-white"
                        >
                          {isEditingMessage ? <Save className="w-4 h-4" /> : <Edit2 className="w-4 h-4" />}
                        </button>
                      </div>
                      
                      {isEditingMessage ? (
                        <textarea
                          value={tempMessage}
                          onChange={(e) => setTempMessage(e.target.value)}
                          placeholder="나에게 해주고 싶은 말을 적어보세요..."
                          className="w-full bg-white/5 rounded-xl p-4 text-gray-100 focus:outline-none focus:ring-1 focus:ring-pink-500/50 min-h-[100px] resize-none"
                        />
                      ) : (
                        <p className="text-lg text-gray-100 leading-relaxed min-h-[60px] whitespace-pre-wrap">
                          {personalMessage || "아직 등록된 응원 문구가 없습니다. 우측 상단 버튼을 눌러 나만의 문구를 작성해보세요."}
                        </p>
                      )}
                    </div>
                  )}

                  <div className="text-center py-4">
                    <p className="text-gray-400 text-sm uppercase tracking-[0.2em] mb-2">Today's Reflection</p>
                    <h2 className="text-2xl font-bold">오늘의 한 줄 위로</h2>
                  </div>

                  <div className="glass-card p-6 rounded-[2.5rem] text-center relative overflow-hidden group min-h-[240px] flex items-center justify-center">
                    <div className="absolute top-0 left-0 w-full h-1 bg-gradient-to-r from-pink-500/50 to-purple-500/50 opacity-50" />
                    <QuoteIcon className="w-12 h-12 text-pink-500/20 absolute top-8 left-8" />
                    <p className="text-2xl leading-relaxed text-gray-100 font-medium relative z-10 py-6 italic">
                      {currentQuote ? `"${currentQuote.text}"` : "등록된 문구가 없습니다. 문구를 추가해 보세요!"}
                    </p>
                    <QuoteIcon className="w-12 h-12 text-pink-500/20 absolute bottom-8 right-8 rotate-180" />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div className="glass-card p-6 rounded-[2rem] flex flex-col gap-3">
                      <div className="w-10 h-10 bg-pink-500/10 rounded-xl flex items-center justify-center text-pink-400">
                        <Bell className="w-5 h-5" />
                      </div>
                      <div>
                        <p className="text-[10px] text-gray-500 font-bold uppercase tracking-widest mb-1">알림 시간</p>
                        <p className="text-lg font-bold">{scheduledTime ? formatTime(scheduledTime) : '설정 안 됨'}</p>
                      </div>
                    </div>
                    <div className="glass-card p-6 rounded-[2rem] flex flex-col gap-3">
                      <div className="w-10 h-10 bg-purple-500/10 rounded-xl flex items-center justify-center text-purple-400">
                        <QuoteIcon className="w-5 h-5" />
                      </div>
                      <div>
                        <p className="text-[10px] text-gray-500 font-bold uppercase tracking-widest mb-1">등록된 문구</p>
                        <p className="text-lg font-bold">{quotes.length}개</p>
                      </div>
                    </div>
                  </div>
                </div>
              )}

              {currentView === 'breathe' && <BreathingGuide />}
              {currentView === 'sound' && <Soundscape />}
              {currentView === 'journal' && <Journal />}
            </motion.div>
          </AnimatePresence>
          </div>

          {/* Bottom Navigation */}
          <nav className="absolute bottom-6 left-0 right-0 mx-auto w-[92%] max-w-[380px] nav-glass rounded-[2rem] p-1 flex items-center justify-center z-50 shadow-2xl border-white/10">
            {[
              { id: 'home', icon: Home, label: '홈' },
              { id: 'breathe', icon: Wind, label: '호흡' },
              { id: 'sound', icon: Music, label: '사운드' },
              { id: 'journal', icon: BookHeart, label: '기록' },
            ].map((item) => (
              <button
                key={item.id}
                onClick={() => setCurrentView(item.id as View)}
                className={`flex-1 flex flex-col items-center justify-center gap-1 py-2.5 rounded-[1.5rem] transition-all ${currentView === item.id ? 'text-pink-400 bg-white/10' : 'text-gray-500 hover:text-gray-300'}`}
              >
                <item.icon className="w-4.5 h-4.5" />
                <span className="text-[9px] font-bold uppercase tracking-wider">{item.label}</span>
              </button>
            ))}
          </nav>
        </main>

        {/* Settings Modal */}
      <AnimatePresence>
        {isSettingsOpen && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[60] flex items-center justify-center p-6 bg-black/80 backdrop-blur-md"
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              exit={{ scale: 0.9, y: 20 }}
              className="relative w-full max-w-sm glass-card rounded-[3rem] p-8"
            >
              <button 
                onClick={() => setIsSettingsOpen(false)}
                className="absolute top-6 right-6 text-gray-500 hover:text-white transition-colors"
              >
                <X className="w-6 h-6" />
              </button>

              <h2 className="text-2xl font-bold mb-8">설정</h2>
              
              <div className="flex flex-col gap-4">
                {deferredPrompt && (
                  <button 
                    onClick={handleInstallApp}
                    className="w-full p-6 bg-pink-500/10 hover:bg-pink-500/20 border border-pink-500/30 rounded-3xl flex items-center justify-between transition-all group"
                  >
                    <div className="flex items-center gap-4">
                      <Download className="w-6 h-6 text-pink-400 group-hover:scale-110 transition-transform" />
                      <div className="text-left">
                        <span className="font-bold block">앱 설치하기</span>
                        <span className="text-[10px] text-gray-400">홈 화면에 추가하여 더 편하게 사용하세요</span>
                      </div>
                    </div>
                  </button>
                )}

                <button 
                  onClick={() => { setIsTimePickerOpen(true); setIsSettingsOpen(false); }}
                  className="w-full p-6 bg-white/5 hover:bg-white/10 rounded-3xl flex items-center justify-between transition-all"
                >
                  <div className="flex items-center gap-4">
                    <Bell className="w-6 h-6 text-pink-400" />
                    <span className="font-bold">알림 시간 변경</span>
                  </div>
                  <span className="text-sm text-gray-500">{scheduledTime ? formatTime(scheduledTime) : ''}</span>
                </button>

                <button 
                  onClick={() => { setIsQuoteManagerOpen(true); setIsSettingsOpen(false); }}
                  className="w-full p-6 bg-white/5 hover:bg-white/10 rounded-3xl flex items-center justify-between transition-all"
                >
                  <div className="flex items-center gap-4">
                    <QuoteIcon className="w-6 h-6 text-purple-400" />
                    <span className="font-bold">문구 관리</span>
                  </div>
                  <span className="text-sm text-gray-500">{quotes.length}개</span>
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Time Picker Modal */}
      <AnimatePresence>
        {isTimePickerOpen && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[70] flex items-center justify-center p-6 bg-black/80 backdrop-blur-md"
          >
            <div className="relative w-full max-w-sm">
              <button 
                onClick={() => setIsTimePickerOpen(false)}
                className="absolute -top-12 right-0 text-white hover:text-pink-200 transition-colors"
              >
                <X className="w-8 h-8" />
              </button>
              <TimePicker 
                initialTime={scheduledTime || { hours: 9, minutes: 0 }} 
                onSave={handleSaveTime} 
              />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Quote Manager Modal */}
      <AnimatePresence>
        {isQuoteManagerOpen && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-[70] flex items-center justify-center p-6 bg-black/80 backdrop-blur-md"
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              exit={{ scale: 0.9, y: 20 }}
              className="relative w-full max-w-lg glass-card rounded-[3rem] shadow-2xl flex flex-col max-h-[80vh] overflow-hidden"
            >
              <div className="p-8 border-b border-white/5">
                <div className="flex items-center justify-between mb-6">
                  <h2 className="text-2xl font-bold">문구 관리</h2>
                  <button 
                    onClick={() => setIsQuoteManagerOpen(false)}
                    className="text-gray-500 hover:text-white transition-colors"
                  >
                    <X className="w-6 h-6" />
                  </button>
                </div>
                
                <div className="flex gap-2">
                  <input 
                    type="text" 
                    value={newQuoteText}
                    onChange={(e) => setNewQuoteText(e.target.value)}
                    placeholder="새로운 응원 문구를 입력하세요"
                    className="flex-grow bg-white/5 rounded-2xl px-5 py-4 focus:outline-none focus:ring-2 focus:ring-pink-500/50 transition-all text-white placeholder-white/20"
                    onKeyPress={(e) => e.key === 'Enter' && handleAddQuote()}
                  />
                  <button 
                    onClick={handleAddQuote}
                    className="bg-pink-500 hover:bg-pink-600 text-white px-8 py-4 rounded-2xl font-bold transition-all active:scale-95 shadow-lg shadow-pink-500/20"
                  >
                    추가
                  </button>
                </div>
              </div>

              <div className="flex-grow overflow-y-auto p-8 space-y-4">
                {quotes.length === 0 ? (
                  <div className="text-center py-12 text-gray-500">
                    <p>등록된 문구가 없습니다.</p>
                  </div>
                ) : (
                  quotes.map((quote) => (
                    <div key={quote.id} className="bg-white/5 p-5 rounded-[1.5rem] flex items-center justify-between group hover:bg-white/10 transition-all border border-white/5">
                      <p className="text-gray-300 text-sm flex-grow pr-4 leading-relaxed">{quote.text}</p>
                      <button 
                        onClick={() => handleDeleteQuote(quote.id)}
                        className="text-gray-600 hover:text-red-400 transition-colors p-2"
                      >
                        <X className="w-5 h-5" />
                      </button>
                    </div>
                  ))
                )}
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Auth Modal */}
      <AuthModal 
        isOpen={isAuthModalOpen} 
        onClose={() => setIsAuthModalOpen(false)} 
      />

      {/* Success Toast */}
      <AnimatePresence>
        {appState === AppState.SUCCESS && (
          <motion.div 
            initial={{ opacity: 0, y: 50 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 50 }}
            className="fixed bottom-32 left-1/2 -translate-x-1/2 z-[100] bg-pink-500 text-white px-8 py-4 rounded-full shadow-2xl flex items-center gap-3"
          >
            <Heart className="w-5 h-5 fill-current" />
            <p className="font-bold tracking-tight">설정이 저장되었습니다</p>
          </motion.div>
        )}
      </AnimatePresence>
      </div>
    </SoundProvider>
  );
};

export default App;
