import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  connect() {
    this.sessionId = localStorage.getItem('session_id') || this.generateSessionId();
    this.userId = this.element.dataset.userId || null;

    this.trackPageView();
    this.addEventListeners();
  }

  generateSessionId() {
    const sessionId = Math.random().toString(36).slice(2, 11);
    localStorage.setItem('session_id', sessionId);
    return sessionId;
  }

  async trackPageView() {
    try {
      await this.sendEvent({
        type: 'pageview',
        url: window.location.href
      });
    } catch (error) {
      console.error('Failed to track pageview:', error);
    }
  }

  addEventListeners() {
    document.addEventListener('click', (event) => this.trackClick(event));
    document.addEventListener('input', (event) => this.trackInput(event));
  }

  async trackClick(event) {
    try {
      await this.sendEvent({
        type: 'click',
        element: event.target.tagName.toLowerCase(),
        x: event.clientX,
        y: event.clientY
      });
    } catch (error) {
      console.error('Failed to track click event:', error);
    }
  }

  async trackInput(event) {
    if (event.target.type !== 'password') { // Avoid sensitive data logging
      try {
        await this.sendEvent({
          type: 'input',
          element: event.target.tagName.toLowerCase(),
          value: event.target.value
        });
      } catch (error) {
        console.error('Failed to track input event:', error);
      }
    }
  }

  async sendEvent(eventData) {
    const payload = {
      ...eventData,
      timestamp: Date.now(),
      sessionId: this.sessionId,
      userId: this.userId
    };

    try {
      const response = await fetch('/track-event', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        },
        body: JSON.stringify(payload)
      });

      if (!response.ok) {
        const error = new Error(`Server error: ${response.statusText}`);
        error.status = response.status; // Attach status for debugging
        throw error; // Rethrow so it can be handled by caller
      }
    } catch (error) {
      console.error('Failed to send tracking event:', error);
      throw error; // Rethrow to allow external handling
    }
  }

}
