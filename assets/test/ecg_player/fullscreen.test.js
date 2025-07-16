import { describe, it, expect, beforeEach, vi } from 'vitest';
import ECGPlayer from '../../js/hooks/ecg/ecg_player.js';

describe('ECGPlayer - Fullscreen Functionality', () => {
  let ecgPlayer;
  let mockElement;
  let mockFullscreenElement;

  beforeEach(() => {
    ecgPlayer = Object.create(ECGPlayer);
    ecgPlayer.handleEvent = vi.fn();
    ecgPlayer.targetComponent = 'test-component';
    ecgPlayer.displayMode = 'multi';
    ecgPlayer.isFullscreen = false;
    ecgPlayer.backgroundCanvas = null;
    ecgPlayer.waveformCanvas = null;
    ecgPlayer.qrsFlashCanvas = null;
    ecgPlayer.chartWidth = 800;
    ecgPlayer.leadHeight = 150;
    
    // Mock ECG container element
    mockElement = {
      requestFullscreen: vi.fn(),
      webkitRequestFullscreen: vi.fn(),
      mozRequestFullScreen: vi.fn(),
      msRequestFullscreen: vi.fn(),
      classList: {
        add: vi.fn(),
        remove: vi.fn(),
        contains: vi.fn().mockReturnValue(false)
      },
      querySelector: vi.fn(),
      style: {}
    };
    
    mockFullscreenElement = {
      addEventListener: vi.fn(),
      dataset: {},
      classList: {
        add: vi.fn(),
        remove: vi.fn()
      }
    };
    
    ecgPlayer.el = mockElement;
    
    // Mock document fullscreen API
    global.document = {
      ...global.document,
      fullscreenElement: null,
      webkitFullscreenElement: null,
      mozFullScreenElement: null,
      msFullscreenElement: null,
      exitFullscreen: vi.fn(),
      webkitExitFullscreen: vi.fn(),
      mozCancelFullScreen: vi.fn(),
      msExitFullscreen: vi.fn(),
      getElementById: vi.fn().mockReturnValue(mockFullscreenElement),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn()
    };
    
    // Mock methods
    ecgPlayer.recreateCanvasAndRestart = vi.fn();
    ecgPlayer.updateFullscreenStyles = vi.fn();
    ecgPlayer.calculateMedicallyAccurateDimensions = vi.fn();
  });

  describe('Fullscreen Detection', () => {
    describe('isDocumentInFullscreen()', () => {
      beforeEach(() => {
        ecgPlayer.isDocumentInFullscreen = ECGPlayer.isDocumentInFullscreen;
      });

      it('should detect fullscreen via document.fullscreenElement', () => {
        global.document.fullscreenElement = mockElement;
        
        expect(ecgPlayer.isDocumentInFullscreen()).toBe(true);
      });

      it('should detect fullscreen via webkit prefix', () => {
        global.document.webkitFullscreenElement = mockElement;
        
        expect(ecgPlayer.isDocumentInFullscreen()).toBe(true);
      });

      it('should detect fullscreen via moz prefix', () => {
        global.document.mozFullScreenElement = mockElement;
        
        expect(ecgPlayer.isDocumentInFullscreen()).toBe(true);
      });

      it('should detect fullscreen via ms prefix', () => {
        global.document.msFullscreenElement = mockElement;
        
        expect(ecgPlayer.isDocumentInFullscreen()).toBe(true);
      });

      it('should return false when not in fullscreen', () => {
        expect(ecgPlayer.isDocumentInFullscreen()).toBe(false);
      });
    });
  });

  describe('Fullscreen Toggle', () => {
    describe('toggleFullscreen()', () => {
      beforeEach(() => {
        ecgPlayer.toggleFullscreen = ECGPlayer.toggleFullscreen;
        ecgPlayer.requestFullscreen = vi.fn();
        ecgPlayer.exitFullscreen = vi.fn();
        ecgPlayer.isDocumentInFullscreen = vi.fn();
      });

      it('should request fullscreen when not in fullscreen', () => {
        ecgPlayer.isDocumentInFullscreen.mockReturnValue(false);
        
        ecgPlayer.toggleFullscreen();
        
        expect(ecgPlayer.requestFullscreen).toHaveBeenCalled();
      });

      it('should exit fullscreen when in fullscreen', () => {
        ecgPlayer.isDocumentInFullscreen.mockReturnValue(true);
        
        ecgPlayer.toggleFullscreen();
        
        expect(ecgPlayer.exitFullscreen).toHaveBeenCalled();
      });
    });

    describe('requestFullscreen()', () => {
      beforeEach(() => {
        ecgPlayer.requestFullscreen = ECGPlayer.requestFullscreen;
        global.document.getElementById = vi.fn().mockReturnValue(mockElement);
      });

      it('should use standard requestFullscreen API', () => {
        ecgPlayer.requestFullscreen();
        
        expect(global.document.getElementById).toHaveBeenCalledWith('ecg-player-container');
        expect(mockElement.requestFullscreen).toHaveBeenCalled();
      });

      it('should fallback to webkit prefix', () => {
        mockElement.requestFullscreen = undefined;
        
        ecgPlayer.requestFullscreen();
        
        expect(global.document.getElementById).toHaveBeenCalledWith('ecg-player-container');
        expect(mockElement.webkitRequestFullscreen).toHaveBeenCalled();
      });

      it('should fallback to moz prefix', () => {
        mockElement.requestFullscreen = undefined;
        mockElement.webkitRequestFullscreen = undefined;
        
        ecgPlayer.requestFullscreen();
        
        expect(global.document.getElementById).toHaveBeenCalledWith('ecg-player-container');
        expect(mockElement.mozRequestFullScreen).toHaveBeenCalled();
      });

      it('should fallback to ms prefix', () => {
        mockElement.requestFullscreen = undefined;
        mockElement.webkitRequestFullscreen = undefined;
        mockElement.mozRequestFullScreen = undefined;
        
        ecgPlayer.requestFullscreen();
        
        expect(global.document.getElementById).toHaveBeenCalledWith('ecg-player-container');
        expect(mockElement.msRequestFullscreen).toHaveBeenCalled();
      });

      it('should handle unsupported browser gracefully', () => {
        mockElement.requestFullscreen = undefined;
        mockElement.webkitRequestFullscreen = undefined;
        mockElement.mozRequestFullScreen = undefined;
        mockElement.msRequestFullscreen = undefined;
        
        expect(() => ecgPlayer.requestFullscreen()).not.toThrow();
      });
    });

    describe('exitFullscreen()', () => {
      beforeEach(() => {
        ecgPlayer.exitFullscreen = ECGPlayer.exitFullscreen;
      });

      it('should use standard exitFullscreen API', () => {
        ecgPlayer.exitFullscreen();
        
        expect(global.document.exitFullscreen).toHaveBeenCalled();
      });

      it('should fallback to webkit prefix', () => {
        global.document.exitFullscreen = undefined;
        
        ecgPlayer.exitFullscreen();
        
        expect(global.document.webkitExitFullscreen).toHaveBeenCalled();
      });

      it('should fallback to moz prefix', () => {
        global.document.exitFullscreen = undefined;
        global.document.webkitExitFullscreen = undefined;
        
        ecgPlayer.exitFullscreen();
        
        expect(global.document.mozCancelFullScreen).toHaveBeenCalled();
      });

      it('should fallback to ms prefix', () => {
        global.document.exitFullscreen = undefined;
        global.document.webkitExitFullscreen = undefined;
        global.document.mozCancelFullScreen = undefined;
        
        ecgPlayer.exitFullscreen();
        
        expect(global.document.msExitFullscreen).toHaveBeenCalled();
      });

      it('should handle unsupported browser gracefully', () => {
        global.document.exitFullscreen = undefined;
        global.document.webkitExitFullscreen = undefined;
        global.document.mozCancelFullScreen = undefined;
        global.document.msExitFullscreen = undefined;
        
        expect(() => ecgPlayer.exitFullscreen()).not.toThrow();
      });
    });
  });

  describe('Fullscreen Event Listeners', () => {
    describe('setupFullscreenListeners()', () => {
      beforeEach(() => {
        ecgPlayer.setupFullscreenListeners = ECGPlayer.setupFullscreenListeners;
        ecgPlayer.handleFullscreenChange = vi.fn();
      });

      it('should setup fullscreen change event listeners', () => {
        ecgPlayer.setupFullscreenListeners();
        
        expect(global.document.addEventListener).toHaveBeenCalledWith('fullscreenchange', expect.any(Function));
        expect(global.document.addEventListener).toHaveBeenCalledWith('webkitfullscreenchange', expect.any(Function));
        expect(global.document.addEventListener).toHaveBeenCalledWith('mozfullscreenchange', expect.any(Function));
        expect(global.document.addEventListener).toHaveBeenCalledWith('MSFullscreenChange', expect.any(Function));
      });
    });

    describe('handleFullscreenChange()', () => {
      beforeEach(() => {
        ecgPlayer.handleFullscreenChange = ECGPlayer.handleFullscreenChange;
        ecgPlayer.isDocumentInFullscreen = vi.fn();
        ecgPlayer.updateFullscreenStyles = vi.fn();
      });

      it('should update fullscreen state when entering fullscreen', () => {
        ecgPlayer.isDocumentInFullscreen.mockReturnValue(true);
        
        ecgPlayer.handleFullscreenChange();
        
        expect(ecgPlayer.isFullscreen).toBe(true);
        expect(ecgPlayer.updateFullscreenStyles).toHaveBeenCalledWith(true);
        expect(ecgPlayer.recreateCanvasAndRestart).toHaveBeenCalled();
      });

      it('should update fullscreen state when exiting fullscreen', () => {
        ecgPlayer.isFullscreen = true;
        ecgPlayer.isDocumentInFullscreen.mockReturnValue(false);
        
        ecgPlayer.handleFullscreenChange();
        
        expect(ecgPlayer.isFullscreen).toBe(false);
        expect(ecgPlayer.updateFullscreenStyles).toHaveBeenCalledWith(false);
        expect(ecgPlayer.recreateCanvasAndRestart).toHaveBeenCalled();
      });

      it('should not recreate canvas if state unchanged', () => {
        ecgPlayer.isFullscreen = false;
        ecgPlayer.isDocumentInFullscreen.mockReturnValue(false);
        
        ecgPlayer.handleFullscreenChange();
        
        expect(ecgPlayer.recreateCanvasAndRestart).not.toHaveBeenCalled();
      });
    });
  });

  describe('Fullscreen Styling', () => {
    describe('updateFullscreenStyles()', () => {
      beforeEach(() => {
        ecgPlayer.updateFullscreenStyles = ECGPlayer.updateFullscreenStyles;
      });

      it('should handle fullscreen styling (CSS-driven)', () => {
        expect(() => ecgPlayer.updateFullscreenStyles(true)).not.toThrow();
      });

      it('should handle exit fullscreen styling (CSS-driven)', () => {
        expect(() => ecgPlayer.updateFullscreenStyles(false)).not.toThrow();
      });

      it('should not throw when called multiple times', () => {
        ecgPlayer.updateFullscreenStyles(true);
        ecgPlayer.updateFullscreenStyles(false);
        ecgPlayer.updateFullscreenStyles(true);
        
        expect(() => ecgPlayer.updateFullscreenStyles(false)).not.toThrow();
      });
    });
  });

  describe('Keyboard Integration', () => {
    describe('Fullscreen keyboard shortcut', () => {
      beforeEach(() => {
        ecgPlayer.setupKeyboardListeners = ECGPlayer.setupKeyboardListeners;
        ecgPlayer.toggleFullscreen = vi.fn();
        ecgPlayer.switchToNextLead = vi.fn();
        ecgPlayer.switchToPrevLead = vi.fn();
        ecgPlayer.togglePlayback = vi.fn();
        global.document.addEventListener = vi.fn();
      });

      it('should handle "f" key for fullscreen toggle', () => {
        ecgPlayer.setupKeyboardListeners();
        const keydownHandler = global.document.addEventListener.mock.calls[0][1];
        
        keydownHandler({ key: 'f', target: { tagName: 'BODY' }, preventDefault: vi.fn() });
        expect(ecgPlayer.toggleFullscreen).toHaveBeenCalled();
      });

      it('should not trigger fullscreen when typing in input fields', () => {
        ecgPlayer.setupKeyboardListeners();
        const keydownHandler = global.document.addEventListener.mock.calls[0][1];
        
        keydownHandler({ key: 'f', target: { tagName: 'INPUT' }, preventDefault: vi.fn() });
        expect(ecgPlayer.toggleFullscreen).not.toHaveBeenCalled();
      });
    });
  });

  describe('Fullscreen Button', () => {
    describe('setupFullscreenButton()', () => {
      beforeEach(() => {
        ecgPlayer.setupFullscreenButton = ECGPlayer.setupFullscreenButton;
        ecgPlayer.toggleFullscreen = vi.fn();
        mockFullscreenElement.addEventListener = vi.fn();
        mockFullscreenElement.dataset = {};
      });

      it('should setup fullscreen button event listener', () => {
        ecgPlayer.setupFullscreenButton();
        
        expect(global.document.getElementById).toHaveBeenCalledWith('fullscreen-button');
        expect(mockFullscreenElement.addEventListener).toHaveBeenCalledWith('click', expect.any(Function));
        expect(mockFullscreenElement.dataset.listenerAdded).toBe('true');
      });

      it('should not add listener if already added', () => {
        mockFullscreenElement.dataset.listenerAdded = 'true';
        
        ecgPlayer.setupFullscreenButton();
        
        expect(mockFullscreenElement.addEventListener).not.toHaveBeenCalled();
      });

      it('should handle missing button gracefully', () => {
        global.document.getElementById.mockReturnValue(null);
        
        expect(() => ecgPlayer.setupFullscreenButton()).not.toThrow();
      });
    });

    describe('updateFullscreenButton()', () => {
      beforeEach(() => {
        ecgPlayer.updateFullscreenButton = ECGPlayer.updateFullscreenButton;
        mockFullscreenElement.innerHTML = '';
        mockFullscreenElement.title = '';
      });

      it('should show exit fullscreen icon when in fullscreen', () => {
        ecgPlayer.isFullscreen = true;
        
        ecgPlayer.updateFullscreenButton();
        
        expect(mockFullscreenElement.innerHTML).toContain('hero-arrows-pointing-in');
        expect(mockFullscreenElement.title).toBe('Exit Fullscreen (f)');
      });

      it('should show enter fullscreen icon when not in fullscreen', () => {
        ecgPlayer.isFullscreen = false;
        
        ecgPlayer.updateFullscreenButton();
        
        expect(mockFullscreenElement.innerHTML).toContain('hero-arrows-pointing-out');
        expect(mockFullscreenElement.title).toBe('Enter Fullscreen (f)');
      });

      it('should handle missing button gracefully', () => {
        global.document.getElementById.mockReturnValue(null);
        
        expect(() => ecgPlayer.updateFullscreenButton()).not.toThrow();
      });
    });
  });
});