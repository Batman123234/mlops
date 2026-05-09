/* src/app/services/audio.service.ts */
import { Injectable } from '@angular/core';
import { Subject } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class AudioService {
  private synth: SpeechSynthesis = window.speechSynthesis;
  public onEnd$ = new Subject<void>();

  constructor() {
    // Pré-chargement des voix pour Chrome et autres navigateurs
    if (this.synth.onvoiceschanged !== undefined) {
      this.synth.onvoiceschanged = () => {
        this.synth.getVoices();
      };
    }
  }

  /**
   * Lit le texte à voix haute en utilisant window.speechSynthesis.
   * @param text Le texte à lire.
   * @param lang La langue ('fr-FR' ou 'en-US').
   */
  speak(text: string, lang: 'fr-FR' | 'en-US'): void {
    this.stop();

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.lang = lang;
    
    // Paramètres spécifiques pour l'anglais US pour éviter le côté "robotique"
    if (lang === 'en-US') {
      utterance.rate = 0.85;  // Plus lent pour une meilleure articulation
      utterance.pitch = 1.1; // Un ton légèrement plus haut pour paraître plus amical/humain
    } else {
      utterance.rate = 1.0;
      utterance.pitch = 1.0;
    }
    utterance.volume = 1.0;

    // Sélection ultra-sélective pour l'anglais
    const voices = this.synth.getVoices();
    
    // Priorité absolue aux voix Google et Natural pour l'anglais
    const enPremiumVoices = [
      'Google US English',
      'Microsoft Zira',
      'Microsoft David',
      'Samantha',
      'Alex'
    ];
    
    let selectedVoice: SpeechSynthesisVoice | null = null;

    if (lang === 'en-US') {
      // 1. Chercher exactement les voix premium connues
      for (const name of enPremiumVoices) {
        const found = voices.find(v => v.name.includes(name));
        if (found) {
          selectedVoice = found;
          break;
        }
      }
    }

    // 2. Fallback sur la logique précédente si pas trouvé ou si français
    if (!selectedVoice) {
      const premiumKeywords = ['Google', 'Natural', 'Premium', 'Enhanced', 'Microsoft', 'Apple'];
      const sortedVoices = voices
        .filter(v => v.lang === lang || v.lang.startsWith(lang.split('-')[0]))
        .sort((a, b) => {
          const aPremium = premiumKeywords.some(key => a.name.includes(key)) ? 0 : 1;
          const bPremium = premiumKeywords.some(key => b.name.includes(key)) ? 0 : 1;
          return aPremium - bPremium;
        });
      selectedVoice = sortedVoices[0] || null;
    }

    if (selectedVoice) {
      utterance.voice = selectedVoice;
      console.log(`[TTS] Using ${lang} voice: ${selectedVoice.name}`);
    }

    utterance.onend = () => {
      this.onEnd$.next();
    };

    utterance.onerror = (err) => {
      console.error('SpeechSynthesis error:', err);
      this.onEnd$.next();
    };

    this.synth.speak(utterance);
  }

  /**
   * Arrête toute lecture en cours.
   */
  stop(): void {
    if (this.synth.speaking) {
      this.synth.cancel();
    }
  }

  /**
   * Indique si une lecture est en cours.
   */
  isSpeaking(): boolean {
    return this.synth.speaking;
  }
}
