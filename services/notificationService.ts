
import { HEALING_QUOTES } from '../constants';
import { Quote } from '../types';

class NotificationService {
  async requestPermission(): Promise<boolean> {
    if (!('Notification' in window)) {
      console.warn('이 브라우저는 알림을 지원하지 않습니다.');
      return false;
    }

    if (Notification.permission === 'granted') {
      return true;
    }

    const permission = await Notification.requestPermission();
    return permission === 'granted';
  }

  async showRandomQuote(customQuotes?: Quote[]): Promise<void> {
    if (Notification.permission !== 'granted') {
      return;
    }

    const quotesSource = customQuotes && customQuotes.length > 0 ? customQuotes : HEALING_QUOTES;
    const randomIndex = Math.floor(Math.random() * quotesSource.length);
    const quote = quotesSource[randomIndex];

    const title = '힐링 모먼트';
    const options: any = {
      body: quote.text,
      icon: 'https://cdn-icons-png.flaticon.com/512/3209/3209931.png',
      badge: 'https://cdn-icons-png.flaticon.com/512/3209/3209931.png',
      tag: 'healing-quote',
      renotify: true,
      requireInteraction: true,
      data: {
        url: window.location.origin
      }
    };

    try {
      const registration = await navigator.serviceWorker.ready;
      await registration.showNotification(title, options);
    } catch (e) {
      console.warn('Service Worker notification failed, falling back to standard Notification API', e);
      new Notification(title, options);
    }
  }

  getPermissionStatus(): NotificationPermission {
    return Notification.permission;
  }
}

export const notificationService = new NotificationService();
