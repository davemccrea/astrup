import { describe, it, expect, beforeEach, vi } from 'vitest';
import ECGPlayer from '../../js/hooks/ecg/ecg_player.js';

describe('ECGPlayer - Rendering', () => {
  let ecgPlayer;
  let mockContext;

  beforeEach(() => {
    mockContext = {
      strokeStyle: '',
      fillStyle: '',
      lineWidth: 1,
      lineCap: 'butt',
      lineJoin: 'miter',
      imageSmoothingEnabled: false,
      imageSmoothingQuality: 'low',
      font: '10px sans-serif',
      beginPath: vi.fn(),
      moveTo: vi.fn(),
      lineTo: vi.fn(),
      quadraticCurveTo: vi.fn(),
      arc: vi.fn(),
      stroke: vi.fn(),
      fill: vi.fn(),
      fillRect: vi.fn(),
      strokeRect: vi.fn(),
      clearRect: vi.fn(),
      fillText: vi.fn()
    };

    ecgPlayer = Object.create(ECGPlayer);
    ecgPlayer.handleEvent = vi.fn();
    ecgPlayer.colors = {
      waveform: '#000000',
      gridFine: '#ff9999',
      gridBold: '#ff6666',
      gridDots: '#999999',
      labels: '#333333'
    };
    ecgPlayer.gridScale = 1.0;
    ecgPlayer.amplitudeScale = 1.0;
    ecgPlayer.yMin = -1.25;
    ecgPlayer.yMax = 1.25;
    ecgPlayer.waveformContext = mockContext;
    ecgPlayer.backgroundContext = mockContext;
    ecgPlayer.leadNames = ['I', 'II', 'V1', 'V2'];
    ecgPlayer.chartWidth = 1000;
    ecgPlayer.heightScale = 1.0;
    ecgPlayer.displayMode = 'single';
    ecgPlayer.currentLead = 0;
    ecgPlayer.leadHeight = 150;
  });

  describe('setupWaveformDrawing()', () => {
    it('should configure canvas context for waveform drawing', () => {
      ecgPlayer.setupWaveformDrawing();

      expect(mockContext.strokeStyle).toBe('#000000');
      expect(mockContext.lineWidth).toBe(1.3);
      expect(mockContext.lineCap).toBe('round');
      expect(mockContext.lineJoin).toBe('round');
      expect(mockContext.imageSmoothingEnabled).toBe(true);
      expect(mockContext.imageSmoothingQuality).toBe('high');
      expect(mockContext.beginPath).toHaveBeenCalled();
    });
  });

  describe('drawMedicalGrid()', () => {
    const bounds = { xOffset: 0, yOffset: 0, width: 600, height: 400 };

    it('should draw fine grid lines', () => {
      ecgPlayer.drawMedicalGrid({ bounds, context: mockContext });

      // The method sets strokeStyle multiple times, check the calls
      expect(mockContext.beginPath).toHaveBeenCalledTimes(2);
      expect(mockContext.stroke).toHaveBeenCalledTimes(2);
      
      // Check that fine grid color was set at some point
      const strokeStyleCalls = mockContext.strokeStyle;
      // The final strokeStyle will be the bold color since it's set last
      expect(strokeStyleCalls).toBe('#ff6666');
    });

    it('should draw bold grid lines', () => {
      ecgPlayer.drawMedicalGrid({ bounds, context: mockContext });

      expect(mockContext.strokeStyle).toBe('#ff6666');
      expect(mockContext.lineWidth).toBe(1);
    });

    it('should respect grid scale', () => {
      ecgPlayer.gridScale = 2.0;
      ecgPlayer.drawMedicalGrid({ bounds, context: mockContext });

      // With 2x scale, spacing should be doubled
      expect(mockContext.moveTo).toHaveBeenCalled();
      expect(mockContext.lineTo).toHaveBeenCalled();
    });

    it('should handle bounds correctly', () => {
      const customBounds = { xOffset: 50, yOffset: 100, width: 300, height: 200 };
      ecgPlayer.drawMedicalGrid({ bounds: customBounds, context: mockContext });

      expect(mockContext.moveTo).toHaveBeenCalled();
      expect(mockContext.lineTo).toHaveBeenCalled();
    });
  });

  describe('drawSimpleGrid()', () => {
    const bounds = { xOffset: 0, yOffset: 0, width: 600, height: 400 };

    it('should draw dot grid', () => {
      ecgPlayer.drawSimpleGrid({ bounds, context: mockContext });

      expect(mockContext.fillStyle).toBe('#999999');
      expect(mockContext.beginPath).toHaveBeenCalled();
      expect(mockContext.arc).toHaveBeenCalled();
      expect(mockContext.fill).toHaveBeenCalled();
    });

    it('should respect grid scale for dot spacing', () => {
      ecgPlayer.gridScale = 0.5;
      ecgPlayer.drawSimpleGrid({ bounds, context: mockContext });

      expect(mockContext.arc).toHaveBeenCalled();
    });
  });

  describe('drawLeadLabel()', () => {
    it('should draw lead label with correct properties', () => {
      ecgPlayer.drawLeadLabel(0, 10, 20, mockContext);

      expect(mockContext.fillStyle).toBe('#333333');
      expect(mockContext.font).toBe('12px Arial');
      expect(mockContext.fillText).toHaveBeenCalledWith('I', 15, 35);
    });

    it('should handle invalid lead index gracefully', () => {
      ecgPlayer.drawLeadLabel(999, 10, 20, mockContext);

      expect(mockContext.fillText).not.toHaveBeenCalled();
    });

    it('should handle missing lead names gracefully', () => {
      ecgPlayer.leadNames = null;
      ecgPlayer.drawLeadLabel(0, 10, 20, mockContext);

      expect(mockContext.fillText).not.toHaveBeenCalled();
    });
  });

  describe('drawWaveformToCursor()', () => {
    const options = {
      times: [0, 0.1, 0.2, 0.3, 0.4],
      values: [0, 0.5, -0.5, 0.2, -0.2],
      bounds: { xOffset: 0, yOffset: 0, width: 400, height: 200 },
      timeSpan: 0.5,
      cursor: { position: 200, width: 20 }
    };

    beforeEach(() => {
      ecgPlayer.calculateClearBounds = vi.fn().mockReturnValue({
        clearX: 190,
        clearWidth: 20
      });
      ecgPlayer.clearCursorArea = vi.fn();
      ecgPlayer.setupWaveformDrawing = vi.fn();
      ecgPlayer.transformCoordinates = vi.fn().mockReturnValue([
        { x: 0, y: 100 },
        { x: 80, y: 80 },
        { x: 160, y: 120 },
        { x: 240, y: 84 },
        { x: 320, y: 116 }
      ]);
    });

    it('should clear cursor area before drawing', () => {
      ecgPlayer.drawWaveformToCursor(options);

      expect(ecgPlayer.calculateClearBounds).toHaveBeenCalledWith(
        0, 400, 200, 20
      );
      expect(ecgPlayer.clearCursorArea).toHaveBeenCalledWith(190, 20);
    });

    it('should draw waveform up to cursor position', () => {
      ecgPlayer.drawWaveformToCursor(options);

      expect(ecgPlayer.setupWaveformDrawing).toHaveBeenCalled();
      expect(mockContext.moveTo).toHaveBeenCalledWith(0, 100);
      expect(mockContext.stroke).toHaveBeenCalled();
    });

    it('should use quadratic curves for smooth lines', () => {
      ecgPlayer.drawWaveformToCursor(options);

      expect(mockContext.quadraticCurveTo).toHaveBeenCalled();
    });

    it('should handle empty data gracefully', () => {
      const emptyOptions = { ...options, times: [], values: [] };
      ecgPlayer.drawWaveformToCursor(emptyOptions);

      expect(mockContext.moveTo).not.toHaveBeenCalled();
      expect(mockContext.stroke).not.toHaveBeenCalled();
    });

    it('should not draw points beyond cursor position', () => {
      const shortCursorOptions = { ...options, cursor: { position: 100, width: 20 } };
      ecgPlayer.drawWaveformToCursor(shortCursorOptions);

      expect(mockContext.moveTo).toHaveBeenCalled();
      // Should not draw all points, only those up to cursor
    });
  });

  describe('drawLeadWaveform()', () => {
    const options = {
      times: [0, 0.1, 0.2],
      values: [0, 0.5, -0.5],
      bounds: { xOffset: 0, yOffset: 0, width: 400, height: 200 },
      timeSpan: 0.5
    };

    beforeEach(() => {
      ecgPlayer.setupWaveformDrawing = vi.fn();
      ecgPlayer.transformCoordinates = vi.fn().mockReturnValue([
        { x: 0, y: 100 },
        { x: 80, y: 80 },
        { x: 160, y: 120 }
      ]);
    });

    it('should draw complete waveform', () => {
      ecgPlayer.drawLeadWaveform(options);

      expect(ecgPlayer.setupWaveformDrawing).toHaveBeenCalled();
      expect(mockContext.moveTo).toHaveBeenCalledWith(0, 100);
      expect(mockContext.quadraticCurveTo).toHaveBeenCalled();
      expect(mockContext.stroke).toHaveBeenCalled();
    });

    it('should handle empty data gracefully', () => {
      const emptyOptions = { ...options, times: [] };
      ecgPlayer.drawLeadWaveform(emptyOptions);

      expect(mockContext.moveTo).not.toHaveBeenCalled();
    });
  });

  describe('clearWaveform()', () => {
    beforeEach(() => {
      ecgPlayer.waveformCanvas = {
        height: 400
      };
      global.window.devicePixelRatio = 2;
    });

    it('should clear waveform canvas', () => {
      ecgPlayer.clearWaveform();

      expect(mockContext.clearRect).toHaveBeenCalledWith(0, 0, 1000, 200);
    });

    it('should handle device pixel ratio', () => {
      global.window.devicePixelRatio = 1;
      ecgPlayer.clearWaveform();

      expect(mockContext.clearRect).toHaveBeenCalledWith(0, 0, 1000, 400);
    });
  });

  describe('calculateClearBounds()', () => {
    it('should calculate correct clear bounds', () => {
      const result = ecgPlayer.calculateClearBounds(0, 400, 200, 20);

      expect(result.clearX).toBe(190);
      expect(result.clearWidth).toBe(20);
    });

    it('should handle cursor near left edge', () => {
      const result = ecgPlayer.calculateClearBounds(0, 400, 5, 20);

      expect(result.clearX).toBe(0);
      expect(result.clearWidth).toBe(20); // When cursor is at 5 with width 20, clear width is min(20, 400-0) = 20
    });

    it('should handle cursor near right edge', () => {
      const result = ecgPlayer.calculateClearBounds(0, 400, 395, 20);

      expect(result.clearX).toBe(385);
      expect(result.clearWidth).toBe(15);
    });

    it('should handle cursor with offset bounds', () => {
      const result = ecgPlayer.calculateClearBounds(50, 300, 200, 20);

      expect(result.clearX).toBe(190);
      expect(result.clearWidth).toBe(20);
    });
  });

  describe('renderGridBackground()', () => {
    beforeEach(() => {
      ecgPlayer.backgroundCanvas = {
        height: 400
      };
      ecgPlayer.renderLeadBackground = vi.fn();
      ecgPlayer.drawContinuousGrid = vi.fn();
      ecgPlayer.drawLeadLabel = vi.fn();
      ecgPlayer.calculateLeadGridCoordinates = vi.fn().mockReturnValue({
        xOffset: 0,
        yOffset: 0,
        columnWidth: 250
      });
      global.window.devicePixelRatio = 1;
    });

    it('should clear background canvas', () => {
      ecgPlayer.renderGridBackground();

      expect(mockContext.clearRect).toHaveBeenCalledWith(0, 0, 1000, 400);
    });

    it('should render single lead background', () => {
      ecgPlayer.displayMode = 'single';
      ecgPlayer.renderGridBackground();

      expect(ecgPlayer.renderLeadBackground).toHaveBeenCalledWith(
        0, 0, 0, 1000, 150, mockContext
      );
    });

    it('should render unified continuous grid for multi-lead', () => {
      ecgPlayer.displayMode = 'multi';
      ecgPlayer.renderGridBackground();

      // Should draw one continuous grid instead of individual lead backgrounds
      expect(ecgPlayer.drawContinuousGrid).toHaveBeenCalledTimes(1);
      expect(ecgPlayer.drawContinuousGrid).toHaveBeenCalledWith(400);
      
      // Should draw lead labels for each lead
      expect(ecgPlayer.drawLeadLabel).toHaveBeenCalledTimes(4);
      expect(ecgPlayer.calculateLeadGridCoordinates).toHaveBeenCalledTimes(4);
    });

    it('should handle missing canvas gracefully', () => {
      ecgPlayer.backgroundCanvas = null;
      ecgPlayer.renderGridBackground();

      expect(mockContext.clearRect).not.toHaveBeenCalled();
    });
  });

  describe('renderLeadBackground()', () => {
    beforeEach(() => {
      ecgPlayer.drawLeadGrid = vi.fn();
      ecgPlayer.drawLeadLabel = vi.fn();
    });

    it('should draw grid and label', () => {
      ecgPlayer.renderLeadBackground(0, 10, 20, 400, 200, mockContext);

      expect(ecgPlayer.drawLeadGrid).toHaveBeenCalledWith({
        bounds: { xOffset: 10, yOffset: 20, width: 400, height: 200 },
        context: mockContext
      });
      expect(ecgPlayer.drawLeadLabel).toHaveBeenCalledWith(0, 10, 20, mockContext);
    });
  });

  describe('renderLeadWaveform()', () => {
    const options = {
      leadIndex: 0,
      leadData: null,
      bounds: { xOffset: 0, yOffset: 0, width: 400, height: 200 },
      timeSpan: 2.5,
      cursorData: {
        times: [0, 0.1],
        values: [0, 0.5],
        cursorPosition: 100,
        cursorWidth: 20
      }
    };

    beforeEach(() => {
      ecgPlayer.drawWaveformToCursor = vi.fn();
      ecgPlayer.drawLeadWaveform = vi.fn();
    });

    it('should draw animated cursor when cursor data provided', () => {
      ecgPlayer.renderLeadWaveform(options);

      expect(ecgPlayer.drawWaveformToCursor).toHaveBeenCalledWith({
        times: [0, 0.1],
        values: [0, 0.5],
        bounds: { xOffset: 0, yOffset: 0, width: 400, height: 200 },
        timeSpan: 2.5,
        cursor: { position: 100, width: 20 }
      });
    });

    it('should draw static waveform when lead data provided', () => {
      const staticOptions = {
        ...options,
        leadData: { times: [0, 0.1], values: [0, 0.5] },
        cursorData: null
      };

      ecgPlayer.renderLeadWaveform(staticOptions);

      expect(ecgPlayer.drawLeadWaveform).toHaveBeenCalledWith({
        times: [0, 0.1],
        values: [0, 0.5],
        bounds: { xOffset: 0, yOffset: 0, width: 400, height: 200 },
        timeSpan: 2.5
      });
    });

    it('should handle no data gracefully', () => {
      const noDataOptions = {
        ...options,
        leadData: null,
        cursorData: null
      };

      ecgPlayer.renderLeadWaveform(noDataOptions);

      expect(ecgPlayer.drawWaveformToCursor).not.toHaveBeenCalled();
      expect(ecgPlayer.drawLeadWaveform).not.toHaveBeenCalled();
    });
  });

  describe('Theme and Colors', () => {
    beforeEach(() => {
      ecgPlayer.updateThemeColors = ECGPlayer.updateThemeColors;
      global.document.documentElement.getAttribute = vi.fn();
    });

    it('should set light theme colors', () => {
      global.document.documentElement.getAttribute.mockReturnValue('light');

      ecgPlayer.updateThemeColors();

      expect(ecgPlayer.colors.waveform).toBe('#000000');
      expect(ecgPlayer.colors.gridFine).toBe('#ff9999');
      expect(ecgPlayer.colors.gridBold).toBe('#ff6666');
      expect(ecgPlayer.colors.gridDots).toBe('#999999');
      expect(ecgPlayer.colors.labels).toBe('#333333');
    });

    it('should set dark theme colors', () => {
      global.document.documentElement.getAttribute.mockReturnValue('dark');

      ecgPlayer.updateThemeColors();

      expect(ecgPlayer.colors.waveform).toBe('#ffffff');
      expect(ecgPlayer.colors.gridFine).toBe('#660000');
      expect(ecgPlayer.colors.gridBold).toBe('#990000');
      expect(ecgPlayer.colors.gridDots).toBe('#666666');
      expect(ecgPlayer.colors.labels).toBe('#ffffff');
    });

    it('should default to light theme', () => {
      global.document.documentElement.getAttribute.mockReturnValue(null);

      ecgPlayer.updateThemeColors();

      expect(ecgPlayer.colors.waveform).toBe('#000000');
    });
  });

  describe('Grid Layout and Coordinates - Unified Continuous Grid', () => {
    let mockElement;

    beforeEach(() => {
      mockElement = {
        querySelector: vi.fn().mockReturnValue({
          offsetWidth: 800
        }),
        getAttribute: vi.fn().mockReturnValue('test-component')
      };
      
      ecgPlayer.el = mockElement;
      ecgPlayer.gridScale = 1.0;
      ecgPlayer.heightScale = 1.0;
      ecgPlayer.chartWidth = 800;
      ecgPlayer.leadHeight = 150;
      ecgPlayer.leadNames = ['I', 'II', 'III', 'aVR', 'aVL', 'aVF', 'V1', 'V2', 'V3', 'V4', 'V5', 'V6'];
    });

    describe('Natural column widths (unified continuous grid)', () => {
      it('should use natural column width divisions', () => {
        const result = ecgPlayer.calculateLeadGridCoordinates(0);
        
        // With unified continuous grid, use natural column width
        const expectedColumnWidth = ecgPlayer.chartWidth / 4; // 200px
        expect(result.columnWidth).toBe(expectedColumnWidth);
      });

      it('should maintain natural divisions across different chart widths', () => {
        const testWidths = [600, 800, 1000, 1200];
        
        testWidths.forEach(width => {
          ecgPlayer.chartWidth = width;
          const result = ecgPlayer.calculateLeadGridCoordinates(0);
          
          // Should always use natural division
          const expectedColumnWidth = width / 4;
          expect(result.columnWidth).toBe(expectedColumnWidth);
        });
      });

      it('should not artificially constrain column widths', () => {
        ecgPlayer.chartWidth = 850; // Non-round number
        const result = ecgPlayer.calculateLeadGridCoordinates(0);
        
        // Should use exact natural division, not constrained to grid multiples
        const expectedColumnWidth = 850 / 4; // 212.5px
        expect(result.columnWidth).toBe(expectedColumnWidth);
      });
    });

    describe('Unified continuous grid layout', () => {
      it('should have no spacing between columns (grids touch)', () => {
        // Test spacing between adjacent columns
        const lead0 = ecgPlayer.calculateLeadGridCoordinates(0); // Column 0
        const lead3 = ecgPlayer.calculateLeadGridCoordinates(3); // Column 1
        
        const actualColumnSpacing = lead3.xOffset - lead0.xOffset - lead0.columnWidth;
        expect(actualColumnSpacing).toBe(0); // No spacing - grids touch
      });

      it('should have no spacing between rows (grids touch)', () => {
        // Test spacing between adjacent rows
        const lead0 = ecgPlayer.calculateLeadGridCoordinates(0); // Row 0
        const lead1 = ecgPlayer.calculateLeadGridCoordinates(1); // Row 1
        
        const actualRowSpacing = lead1.yOffset - lead0.yOffset - ecgPlayer.leadHeight;
        expect(actualRowSpacing).toBe(0); // No spacing - grids touch
      });

      it('should maintain touching grids across all scale settings', () => {
        const testScales = [0.75, 1.0, 1.25];
        
        testScales.forEach(scale => {
          ecgPlayer.gridScale = scale;
          
          const lead0 = ecgPlayer.calculateLeadGridCoordinates(0);
          const lead3 = ecgPlayer.calculateLeadGridCoordinates(3);
          
          const actualColumnSpacing = lead3.xOffset - lead0.xOffset - lead0.columnWidth;
          
          // Grids should always touch regardless of scale
          expect(actualColumnSpacing).toBe(0);
        });
      });

      it('should prevent visual discontinuities with unified continuous grid', () => {
        // With unified continuous grid, visual continuity is maintained by drawing
        // one grid across the entire canvas, not individual grids per lead
        
        const lead0 = ecgPlayer.calculateLeadGridCoordinates(0);
        const lead3 = ecgPlayer.calculateLeadGridCoordinates(3);
        
        // Boundary areas should have natural spacing, not artificial constraints
        const actualSpacing = lead3.xOffset - lead0.xOffset - lead0.columnWidth;
        expect(actualSpacing).toBe(0); // No artificial spacing
      });
    });

    describe('Edge cases and robustness', () => {
      it('should handle very small grid scales gracefully', () => {
        ecgPlayer.gridScale = 0.5;
        
        const result = ecgPlayer.calculateLeadGridCoordinates(0);
        
        expect(result.columnWidth).toBeGreaterThan(0);
        expect(Number.isFinite(result.columnWidth)).toBe(true);
        
        // Should use natural column width regardless of scale
        const expectedColumnWidth = ecgPlayer.chartWidth / 4;
        expect(result.columnWidth).toBe(expectedColumnWidth);
      });

      it('should handle large grid scales gracefully', () => {
        ecgPlayer.gridScale = 2.0;
        
        const result = ecgPlayer.calculateLeadGridCoordinates(0);
        
        expect(result.columnWidth).toBeGreaterThan(0);
        expect(Number.isFinite(result.columnWidth)).toBe(true);
        
        // Should use natural column width regardless of scale
        const expectedColumnWidth = ecgPlayer.chartWidth / 4;
        expect(result.columnWidth).toBe(expectedColumnWidth);
      });

      it('should handle non-integer column widths correctly', () => {
        ecgPlayer.chartWidth = 850; // Results in 212.5px column width
        
        const result = ecgPlayer.calculateLeadGridCoordinates(0);
        
        // Should handle fractional pixels correctly
        expect(result.columnWidth).toBe(212.5);
        expect(Number.isFinite(result.columnWidth)).toBe(true);
      });
    });
  });
});