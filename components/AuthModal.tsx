import React, { useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { X, Mail, Lock, LogIn, UserPlus } from 'lucide-react';
import { auth, db } from '../firebase';
import { 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword,
  updateProfile
} from 'firebase/auth';
import { doc, setDoc, getDocs, collection } from 'firebase/firestore';

interface AuthModalProps {
  isOpen: boolean;
  onClose: () => void;
}

const AuthModal: React.FC<AuthModalProps> = ({ isOpen, onClose }) => {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setIsLoading(true);

    if (!auth) {
      setError('Firebase not initialized');
      setIsLoading(false);
      return;
    }

    try {
      if (isLogin) {
        await signInWithEmailAndPassword(auth, email, password);
      } else {
        const userCredential = await createUserWithEmailAndPassword(auth, email, password);
        const user = userCredential.user;
        
        // Set initial profile
        await updateProfile(user, {
          displayName: email.split('@')[0]
        });

        // Store user role in Firestore
        if (db) {
          // Check if any users exist
          const usersSnap = await getDocs(collection(db, 'users'));
          const isFirstUser = usersSnap.empty;
          
          // Default role is 'user', but the first user or specific email is 'admin'
          const role = (isFirstUser || email.toLowerCase() === 'admin@healing.com') ? 'admin' : 'user';
          
          await setDoc(doc(db, 'users', user.uid), {
            email: user.email,
            role: role,
            createdAt: new Date().toISOString()
          });
        }
      }
      onClose();
    } catch (err: any) {
      console.error('Auth error detailed:', err);
      let message = `인증에 실패했습니다. (에러 코드: ${err.code || 'unknown'})`;
      if (err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
        message = '이메일 또는 비밀번호가 올바르지 않습니다.';
      } else if (err.code === 'auth/email-already-in-use') {
        message = '이미 사용 중인 이메일입니다.';
      } else if (err.code === 'auth/weak-password') {
        message = '비밀번호가 너무 취약합니다.';
      } else if (err.code === 'auth/invalid-email') {
        message = '유효하지 않은 이메일 형식입니다.';
      }
      setError(message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <AnimatePresence>
      {isOpen && (
        <>
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50"
          />
          <motion.div
            initial={{ opacity: 0, scale: 0.95, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.95, y: 20 }}
            className="fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-full max-w-md z-50 p-4"
          >
            <div className="bg-[#1a1b1e] border border-white/10 rounded-3xl p-8 shadow-2xl relative overflow-hidden">
              {/* Background Glow */}
              <div className="absolute top-0 left-0 w-full h-full bg-gradient-to-br from-pink-500/10 via-transparent to-blue-500/10 pointer-events-none" />
              
              <button
                onClick={onClose}
                className="absolute top-4 right-4 text-gray-400 hover:text-white transition-colors"
              >
                <X className="w-5 h-5" />
              </button>

              <div className="relative z-10">
                <h2 className="text-2xl font-bold mb-2 text-center">
                  {isLogin ? '환영합니다' : '회원가입'}
                </h2>
                <p className="text-gray-400 text-sm text-center mb-8">
                  {isLogin ? '나만의 힐링 공간으로 입장하세요' : '새로운 여정을 시작해보세요'}
                </p>

                <form onSubmit={handleSubmit} className="space-y-4">
                  <div className="space-y-2">
                    <label className="text-sm text-gray-400 ml-1">이메일</label>
                    <div className="relative">
                      <Mail className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500" />
                      <input
                        type="email"
                        value={email}
                        onChange={(e) => setEmail(e.target.value)}
                        className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white placeholder-gray-500 focus:outline-none focus:border-pink-500/50 focus:bg-white/10 transition-all"
                        placeholder="example@email.com"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-2">
                    <label className="text-sm text-gray-400 ml-1">비밀번호</label>
                    <div className="relative">
                      <Lock className="absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-500" />
                      <input
                        type="password"
                        value={password}
                        onChange={(e) => setPassword(e.target.value)}
                        className="w-full bg-white/5 border border-white/10 rounded-xl py-3 pl-12 pr-4 text-white placeholder-gray-500 focus:outline-none focus:border-pink-500/50 focus:bg-white/10 transition-all"
                        placeholder="••••••••"
                        required
                      />
                    </div>
                  </div>

                  {error && (
                    <div className="text-red-400 text-sm text-center bg-red-500/10 py-2 rounded-lg border border-red-500/20">
                      {error}
                    </div>
                  )}

                  <button
                    type="submit"
                    disabled={isLoading}
                    className="w-full bg-gradient-to-r from-pink-500 to-rose-500 text-white font-medium py-3 rounded-xl hover:opacity-90 transition-opacity disabled:opacity-50 flex items-center justify-center gap-2 mt-4"
                  >
                    {isLoading ? (
                      <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                    ) : (
                      <>
                        {isLogin ? <LogIn className="w-5 h-5" /> : <UserPlus className="w-5 h-5" />}
                        {isLogin ? '로그인' : '가입하기'}
                      </>
                    )}
                  </button>
                </form>

                <div className="mt-6 text-center">
                  <button
                    onClick={() => {
                      setIsLogin(!isLogin);
                      setError('');
                      setEmail('');
                      setPassword('');
                    }}
                    className="text-sm text-gray-400 hover:text-white transition-colors underline underline-offset-4"
                  >
                    {isLogin ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인'}
                  </button>
                </div>
              </div>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
};

export default AuthModal;
