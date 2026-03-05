
import { Quote, SoundscapeData, BreathingAudioData } from './types';

export const HEALING_QUOTES: Quote[] = [
  { id: 1, text: "오늘 하루도 정말 고생 많았어요. 당신은 충분히 잘하고 있습니다." },
  { id: 2, text: "잠시 숨을 크게 들이마셔 보세요. 평온함이 당신과 함께할 거예요." },
  { id: 3, text: "당신은 생각보다 훨씬 더 강하고 아름다운 사람입니다." },
  { id: 4, text: "작은 발걸음들이 모여 커다란 변화를 만들어낼 거예요. 조급해하지 마세요." },
  { id: 5, text: "어제의 실수보다는 오늘의 가능성에 집중해보는 건 어떨까요?" },
  { id: 6, text: "당신은 존재 자체만으로도 소중하고 가치 있는 사람입니다." },
  { id: 7, text: "지치고 힘들 때는 잠시 쉬어가도 괜찮아요. 그것도 용기입니다." },
  { id: 8, text: "당신의 노력은 결코 헛되지 않아요. 언젠가 밝게 빛날 거예요." },
  { id: 9, text: "오늘 하루, 스스로에게 '고마워'라고 한마디 건네주세요." },
  { id: 10, text: "세상의 속도에 맞추려 애쓰지 마세요. 당신만의 속도가 가장 소중합니다." },
  { id: 11, text: "가장 어두운 밤 뒤에는 반드시 가장 밝은 해가 떠오릅니다." },
  { id: 12, text: "지금 이 순간의 평화가 당신의 마음속에 가득하기를 바랍니다." },
  { id: 13, text: "당신은 누구보다 자신을 사랑할 자격이 있는 사람입니다." },
  { id: 14, text: "걱정은 내일의 구름일 뿐이에요. 오늘이라는 햇살을 즐겨보세요." },
  { id: 15, text: "친절함은 자신에게 먼저 베푸는 것에서 시작됩니다." },
  { id: 16, text: "꽃마다 피는 시기가 다르듯, 당신의 계절도 곧 찾아올 거예요." },
  { id: 17, text: "마음이 시키는 소리에 귀를 기울여 보세요. 정답은 이미 당신 안에 있습니다." },
  { id: 18, text: "비온 뒤 땅이 굳어지듯, 지금의 시련이 당신을 더 단단하게 해줄 거예요." },
  { id: 19, text: "꿈을 향해 걷는 당신의 뒷모습은 그 무엇보다 아름답습니다." },
  { id: 20, text: "행복은 멀리 있지 않아요. 지금 당신 곁의 작은 순간들 속에 있답니다." }
];

export const DEFAULT_SOUNDSCAPES: SoundscapeData[] = [
  { id: 'rain', name: '비 오는 날의 도서관', iconName: 'library', url: 'https://cdn.pixabay.com/audio/2022/07/04/audio_2463276710.mp3', color: 'bg-blue-500/20' },
  { id: 'fire', name: '모닥불 타오르는 밤', iconName: 'flame', url: 'https://cdn.pixabay.com/audio/2021/09/06/audio_173872019b.mp3', color: 'bg-orange-500/20' },
  { id: 'waves', name: '제주도 바다 파도', iconName: 'waves', url: 'https://cdn.pixabay.com/audio/2022/02/07/audio_6e53745425.mp3', color: 'bg-cyan-500/20' },
  { id: 'cafe', name: '조용한 오후의 카페', iconName: 'coffee', url: 'https://cdn.pixabay.com/audio/2022/03/23/audio_07b2a04be3.mp3', color: 'bg-amber-500/20' },
  { id: 'forest', name: '바람 부는 숲 속', iconName: 'cloudRain', url: 'https://cdn.pixabay.com/audio/2021/09/06/audio_9c05c0a27d.mp3', color: 'bg-green-500/20' },
];

export const DEFAULT_BREATHING_AUDIO: BreathingAudioData = {
  url: 'https://cdn.pixabay.com/audio/2022/05/27/audio_1808fbf07a.mp3'
};

export const STORAGE_KEY = 'healing_moments_scheduled_time';
export const QUOTES_STORAGE_KEY = 'healing_moments_quotes';
