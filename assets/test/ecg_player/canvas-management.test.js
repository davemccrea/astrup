import { describe, it, expect, beforeEach, vi } from 'vitest';
import ECGPlayer from '../../js/hooks/ecg/ecg_player.js';

describe('ECGPlayer - Canvas Management', () => {
  let ecgPlayer;
  let mockContainer;
  let mockCanvas;
  let mockContext;

  beforeEach(() => {
    // Mock canvas context
    mockContext = {
      scale: vi.fn(),
      clearRect: vi.fn(),
      strokeStyle: '',
      fillStyle: '',
      lineWidth: 1,
      beginPath: vi.fn(),
      moveTo: vi.fn(),
      lineTo: vi.fn(),
      stroke: vi.fn(),
      fill: vi.fn()
    };

    // Mock canvas element
    mockCanvas = {
      width: 0,
      height: 0,
      style: {},
      getContext: vi.fn().mockReturnValue(mockContext),
      remove: vi.fn(),
      addEventListener: vi.fn(),
      removeEventListener: vi.fn(),
      getBoundingClientRect: vi.fn().mockReturnValue({
        left: 0,
        top: 0,
        width: 800,
        height: 600
      })
    };

    // Mock container element
    mockContainer = {
      offsetWidth: 800,
      appendChild: vi.fn()
    };

    // Mock ECG player
    ecgPlayer = Object.create(ECGPlayer);
    ecgPlayer.handleEvent = vi.fn();
    ecgPlayer.el = {
      querySelector: vi.fn().mockReturnValue(mockContainer)
    };
    ecgPlayer.chartWidth = 1000;
    ecgPlayer.heightScale = 1.0;
    ecgPlayer.gridScale = 1.0;
    ecgPlayer.displayMode = 'single';
    ecgPlayer.leadHeight = 150;
    ecgPlayer.setupCanvasClickHandler = vi.fn();
    ecgPlayer.updateCursorStyle = vi.fn();
    
    // Mock document.createElement
    global.document.createElement = vi.fn().mockReturnValue(mockCanvas);
    global.window.devicePixelRatio = 2;
  });

  describe('calculateMedicallyAccurateDimensions()', () => {
    beforeEach(() => {
      ecgPlayer.calculateMedicallyAccurateDimensions = ECGPlayer.calculateMedicallyAccurateDimensions;
      ecgPlayer.gridScale = 1.0;
    });

    it('should calculate dimensions based on container width', () => {
      mockContainer.offsetWidth = 1200;
      
      ecgPlayer.calculateMedicallyAccurateDimensions();
      
      expect(ecgPlayer.chartWidth).toBeGreaterThan(0);
      expect(ecgPlayer.widthSeconds).toBeGreaterThan(0);
    });

    it('should use minimum width when container is too small', () => {
      mockContainer.offsetWidth = 100; // Very small container
      
      ecgPlayer.calculateMedicallyAccurateDimensions();
      
      expect(ecgPlayer.widthSeconds).toBe(2.5); // DEFAULT_WIDTH_SECONDS
    });

    it('should handle missing container gracefully', () => {
      ecgPlayer.el.querySelector.mockReturnValue(null);
      
      ecgPlayer.calculateMedicallyAccurateDimensions();
      
      expect(ecgPlayer.widthSeconds).toBe(2.5);
    });

    it('should account for grid scale in calculations', () => {
      ecgPlayer.gridScale = 2.0;
      mockContainer.offsetWidth = 800;
      
      ecgPlayer.calculateMedicallyAccurateDimensions();
      
      // With 2x scale, chart should be scaled accordingly
      expect(ecgPlayer.chartWidth).toBeGreaterThan(0);
    });
  });

  describe('recreateCanvas()', () => {
    beforeEach(() => {
      ecgPlayer.recreateCanvas = ECGPlayer.recreateCanvas;
      ecgPlayer.cleanupCanvases = vi.fn();
      ecgPlayer.setupCanvasClickHandler = vi.fn();
      ecgPlayer.updateCursorStyle = vi.fn();
    });

    it('should create four canvas layers', () => {
      ecgPlayer.recreateCanvas();
      
      expect(global.document.createElement).toHaveBeenCalledTimes(4);
      expect(global.document.createElement).toHaveBeenCalledWith('canvas');
      expect(mockContainer.appendChild).toHaveBeenCalledTimes(4);
    });

    it('should set up canvas dimensions correctly', () => {
      ecgPlayer.recreateCanvas();
      
      expect(mockCanvas.width).toBe(2000); // chartWidth * devicePixelRatio
      expect(mockCanvas.style.width).toBe('1000px');
      expect(mockContext.scale).toHaveBeenCalledWith(2, 2);
    });

    it('should handle different display modes', () => {
      ecgPlayer.displayMode = 'multi';
      ecgPlayer.recreateCanvas();
      
      // Multi-lead mode should have different height calculations
      expect(mockCanvas.height).toBeGreaterThan(0);
    });

    it('should setup canvas layering correctly', () => {
      ecgPlayer.recreateCanvas();
      
      // Check that overlapping styles are set
      expect(mockCanvas.style.marginTop).toBeDefined();
      expect(mockCanvas.style.pointerEvents).toBeDefined();
    });

    it('should cleanup existing canvases first', () => {
      ecgPlayer.recreateCanvas();
      
      expect(ecgPlayer.cleanupCanvases).toHaveBeenCalled();
    });

    it('should setup click handler and cursor style', () => {
      ecgPlayer.recreateCanvas();
      
      expect(ecgPlayer.setupCanvasClickHandler).toHaveBeenCalled();
      expect(ecgPlayer.updateCursorStyle).toHaveBeenCalled();
    });
  });

  describe('cleanupCanvases()', () => {
    beforeEach(() => {
      ecgPlayer.cleanupCanvases = ECGPlayer.cleanupCanvases;
      ecgPlayer.backgroundCanvas = mockCanvas;
      ecgPlayer.waveformCanvas = mockCanvas;
      ecgPlayer.qrsFlashCanvas = mockCanvas;
      ecgPlayer.canvasClickHandler = vi.fn();
    });

    it('should remove all canvas elements', () => {
      ecgPlayer.cleanupCanvases();
      
      expect(mockCanvas.remove).toHaveBeenCalledTimes(3);
    });

    it('should remove event listeners', () => {
      ecgPlayer.cleanupCanvases();
      
      expect(mockCanvas.removeEventListener).toHaveBeenCalledWith('click', ecgPlayer.canvasClickHandler);
    });

    it('should nullify canvas references', () => {
      ecgPlayer.cleanupCanvases();
      
      expect(ecgPlayer.backgroundCanvas).toBe(null);
      expect(ecgPlayer.backgroundContext).toBe(null);
      expect(ecgPlayer.waveformCanvas).toBe(null);
      expect(ecgPlayer.waveformContext).toBe(null);
      expect(ecgPlayer.qrsFlashCanvas).toBe(null);
      expect(ecgPlayer.qrsFlashContext).toBe(null);
    });

    it('should handle missing canvases gracefully', () => {
      ecgPlayer.backgroundCanvas = null;
      ecgPlayer.waveformCanvas = null;
      ecgPlayer.qrsFlashCanvas = null;
      
      expect(() => ecgPlayer.cleanupCanvases()).not.toThrow();
    });
  });

  describe('Canvas Click Handling', () => {
    describe('setupCanvasClickHandler()', () => {
      beforeEach(() => {
        ecgPlayer.setupCanvasClickHandler = ECGPlayer.setupCanvasClickHandler;
        ecgPlayer.backgroundCanvas = mockCanvas;
        ecgPlayer.getLeadIndexFromClick = vi.fn();
        ecgPlayer.switchLead = vi.fn();
        ecgPlayer.updateDisplayModeSelector = vi.fn();
        ecgPlayer.updateLeadSelectorVisibility = vi.fn();
        ecgPlayer.recreateCanvasAndRestart = vi.fn();
        ecgPlayer.updateCursorStyle = vi.fn();
        ecgPlayer.canvasClickHandler = null;
      });

      it('should setup click event listener', () => {
        ecgPlayer.setupCanvasClickHandler();
        
        expect(mockCanvas.addEventListener).toHaveBeenCalledWith('click', expect.any(Function));
      });

      it('should remove existing click handler first', () => {
        const existingHandler = vi.fn();
        ecgPlayer.canvasClickHandler = existingHandler;
        
        ecgPlayer.setupCanvasClickHandler();
        
        expect(mockCanvas.removeEventListener).toHaveBeenCalledWith('click', existingHandler);
      });

      it('should handle multi-lead mode clicks', () => {
        ecgPlayer.displayMode = 'multi';
        ecgPlayer.getLeadIndexFromClick.mockReturnValue(2);
        
        ecgPlayer.setupCanvasClickHandler();
        const clickHandler = mockCanvas.addEventListener.mock.calls[0][1];
        
        clickHandler({ clientX: 100, clientY: 50 });
        
        expect(ecgPlayer.getLeadIndexFromClick).toHaveBeenCalledWith(100, 50);
        expect(ecgPlayer.switchLead).toHaveBeenCalledWith(2);
        expect(ecgPlayer.updateDisplayModeSelector).toHaveBeenCalledWith('single');
      });

      it('should handle single-lead mode clicks', () => {
        ecgPlayer.displayMode = 'single';
        
        ecgPlayer.setupCanvasClickHandler();
        const clickHandler = mockCanvas.addEventListener.mock.calls[0][1];
        
        clickHandler({ clientX: 100, clientY: 50 });
        
        expect(ecgPlayer.updateDisplayModeSelector).toHaveBeenCalledWith('multi');
        expect(ecgPlayer.updateLeadSelectorVisibility).toHaveBeenCalledWith('multi');
      });
    });

    describe('getLeadIndexFromClick()', () => {
      beforeEach(() => {
        ecgPlayer.getLeadIndexFromClick = ECGPlayer.getLeadIndexFromClick;
        ecgPlayer.leadNames = ['I', 'II', 'V1', 'V2'];
        ecgPlayer.displayMode = 'multi';
        ecgPlayer.calculateLeadGridCoordinates = vi.fn().mockReturnValue({
          xOffset: 0,
          yOffset: 0,
          columnWidth: 250
        });
        ecgPlayer.leadHeight = 150;
      });

      it('should return correct lead index for click within bounds', () => {
        const result = ecgPlayer.getLeadIndexFromClick(100, 50);
        
        expect(ecgPlayer.calculateLeadGridCoordinates).toHaveBeenCalledWith(0);
        expect(result).toBe(0);
      });

      it('should return null for click outside any lead', () => {
        ecgPlayer.calculateLeadGridCoordinates.mockReturnValue({
          xOffset: 300,
          yOffset: 200,
          columnWidth: 250
        });
        
        const result = ecgPlayer.getLeadIndexFromClick(100, 50);
        
        expect(result).toBe(null);
      });

      it('should return null for invalid display mode', () => {
        ecgPlayer.displayMode = 'single';
        
        const result = ecgPlayer.getLeadIndexFromClick(100, 50);
        
        expect(result).toBe(null);
      });

      it('should handle missing lead names gracefully', () => {
        ecgPlayer.leadNames = null;
        
        const result = ecgPlayer.getLeadIndexFromClick(100, 50);
        
        expect(result).toBe(null);
      });
    });
  });

  describe('Canvas State Preservation', () => {
    describe('withCanvasStatePreservation()', () => {
      beforeEach(() => {
        ecgPlayer.withCanvasStatePreservation = ECGPlayer.withCanvasStatePreservation;
        ecgPlayer.stopAnimation = vi.fn();
        ecgPlayer.startAnimationLoop = vi.fn();
        ecgPlayer.processAnimationFrame = vi.fn();
        ecgPlayer.startTime = 1000;
        ecgPlayer.pausedTime = 2000;
        ecgPlayer.widthSeconds = 2.5;
      });

      it('should preserve playing state', () => {
        ecgPlayer.isPlaying = true;
        const mockOperation = vi.fn();
        
        ecgPlayer.withCanvasStatePreservation(mockOperation);
        
        expect(ecgPlayer.stopAnimation).toHaveBeenCalled();
        expect(mockOperation).toHaveBeenCalled();
        expect(ecgPlayer.isPlaying).toBe(true);
        expect(ecgPlayer.startAnimationLoop).toHaveBeenCalled();
      });

      it('should preserve paused state', () => {
        ecgPlayer.isPlaying = false;
        const mockOperation = vi.fn();
        
        ecgPlayer.withCanvasStatePreservation(mockOperation);
        
        expect(mockOperation).toHaveBeenCalled();
        expect(ecgPlayer.processAnimationFrame).toHaveBeenCalled();
        expect(ecgPlayer.startAnimationLoop).not.toHaveBeenCalled();
      });

      it('should handle missing timing data gracefully', () => {
        ecgPlayer.isPlaying = false;
        ecgPlayer.startTime = null;
        ecgPlayer.pausedTime = 0;
        const mockOperation = vi.fn();
        
        ecgPlayer.withCanvasStatePreservation(mockOperation);
        
        expect(mockOperation).toHaveBeenCalled();
        expect(ecgPlayer.processAnimationFrame).not.toHaveBeenCalled();
      });
    });

    describe('recreateCanvasAndRestart()', () => {
      beforeEach(() => {
        ecgPlayer.recreateCanvasAndRestart = ECGPlayer.recreateCanvasAndRestart;
        ecgPlayer.withCanvasStatePreservation = vi.fn();
        ecgPlayer.recreateCanvas = vi.fn();
        ecgPlayer.renderGridBackground = vi.fn();
      });

      it('should recreate canvas with state preservation', () => {
        ecgPlayer.recreateCanvasAndRestart();
        
        expect(ecgPlayer.withCanvasStatePreservation).toHaveBeenCalledWith(expect.any(Function));
        
        // Call the operation function to verify it calls the right methods
        const operationFn = ecgPlayer.withCanvasStatePreservation.mock.calls[0][0];
        operationFn();
        
        expect(ecgPlayer.recreateCanvas).toHaveBeenCalled();
        expect(ecgPlayer.renderGridBackground).toHaveBeenCalled();
      });
    });
  });

  describe('Cursor Style Management', () => {
    describe('updateCursorStyle()', () => {
      beforeEach(() => {
        ecgPlayer.updateCursorStyle = ECGPlayer.updateCursorStyle;
        ecgPlayer.backgroundCanvas = mockCanvas;
        mockCanvas.style = {};
      });

      it('should set zoom-out cursor for single mode', () => {
        ecgPlayer.displayMode = 'single';
        
        ecgPlayer.updateCursorStyle();
        
        expect(mockCanvas.style.cursor).toBe('zoom-out');
      });

      it('should set zoom-in cursor for multi mode', () => {
        ecgPlayer.displayMode = 'multi';
        
        ecgPlayer.updateCursorStyle();
        
        expect(mockCanvas.style.cursor).toBe('zoom-in');
      });

      it('should handle missing background canvas gracefully', () => {
        ecgPlayer.backgroundCanvas = null;
        
        expect(() => ecgPlayer.updateCursorStyle()).not.toThrow();
      });
    });
  });

  describe('Device Pixel Ratio Handling', () => {
    it('should handle high DPI displays', () => {
      global.window.devicePixelRatio = 3;
      ecgPlayer.recreateCanvas = ECGPlayer.recreateCanvas;
      ecgPlayer.cleanupCanvases = vi.fn();
      
      ecgPlayer.recreateCanvas();
      
      expect(mockCanvas.width).toBe(3000); // chartWidth * devicePixelRatio
      expect(mockContext.scale).toHaveBeenCalledWith(3, 3);
    });

    it('should handle missing devicePixelRatio', () => {
      global.window.devicePixelRatio = undefined;
      ecgPlayer.recreateCanvas = ECGPlayer.recreateCanvas;
      ecgPlayer.cleanupCanvases = vi.fn();
      
      ecgPlayer.recreateCanvas();
      
      expect(mockCanvas.width).toBe(1000); // chartWidth * 1 (default)
      expect(mockContext.scale).toHaveBeenCalledWith(1, 1);
    });
  });

  describe('Multi-lead Layout Calculations', () => {
    describe('getLeadColumnAndRow()', () => {
      beforeEach(() => {
        ecgPlayer.getLeadColumnAndRow = ECGPlayer.getLeadColumnAndRow;
      });

      it('should return correct positions for standard 12-lead layout', () => {
        expect(ecgPlayer.getLeadColumnAndRow(0)).toEqual({ column: 0, row: 0 });
        expect(ecgPlayer.getLeadColumnAndRow(3)).toEqual({ column: 1, row: 0 });
        expect(ecgPlayer.getLeadColumnAndRow(6)).toEqual({ column: 2, row: 0 });
        expect(ecgPlayer.getLeadColumnAndRow(9)).toEqual({ column: 3, row: 0 });
        expect(ecgPlayer.getLeadColumnAndRow(1)).toEqual({ column: 0, row: 1 });
        expect(ecgPlayer.getLeadColumnAndRow(2)).toEqual({ column: 0, row: 2 });
      });

      it('should handle invalid lead index gracefully', () => {
        expect(ecgPlayer.getLeadColumnAndRow(999)).toEqual({ column: 0, row: 0 });
        expect(ecgPlayer.getLeadColumnAndRow(-1)).toEqual({ column: 0, row: 0 });
      });
    });

    describe('calculateLeadGridCoordinates()', () => {
      beforeEach(() => {
        ecgPlayer.calculateLeadGridCoordinates = ECGPlayer.calculateLeadGridCoordinates;
        ecgPlayer.chartWidth = 1000;
        ecgPlayer.leadHeight = 150;
        ecgPlayer.getLeadColumnAndRow = vi.fn().mockReturnValue({ column: 1, row: 2 });
      });

      it('should calculate correct coordinates with unified continuous grid', () => {
        const result = ecgPlayer.calculateLeadGridCoordinates(6);
        
        expect(ecgPlayer.getLeadColumnAndRow).toHaveBeenCalledWith(6);
        
        // With unified continuous grid - natural column width, no artificial constraints
        const expectedColumnWidth = 1000 / 4; // 250px - natural division
        const expectedXOffset = 1 * expectedColumnWidth; // column 1: 250px
        const expectedYOffset = 2 * 150; // row 2: 300px
        
        expect(result.xOffset).toBe(expectedXOffset);
        expect(result.yOffset).toBe(expectedYOffset);
        expect(result.columnWidth).toBe(expectedColumnWidth);
      });

      it('should handle unified continuous grid correctly', () => {
        // Test with different chart width
        ecgPlayer.chartWidth = 800;
        
        const result = ecgPlayer.calculateLeadGridCoordinates(0);
        
        // With unified continuous grid - natural column width
        const expectedColumnWidth = 800 / 4; // 200px - natural division
        
        expect(result.columnWidth).toBe(expectedColumnWidth);
      });
    });
  });
});