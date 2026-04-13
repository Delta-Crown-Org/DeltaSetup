/**
 * Delta Crown Executive Presentation Controller
 * Issue: DeltaSetup-6sh
 * 
 * A comprehensive presentation controller with keyboard navigation,
 * slide transitions, progress indicators, touch support, and more.
 * 
 * @author Tyler Granlund
 * @version 1.0.0
 */

class PresentationController {
  constructor() {
    // Slide tracking
    this.currentSlide = 0;
    this.totalSlides = 13;
    
    // Mode states
    this.isFullscreen = false;
    this.isOverview = false;
    
    // Touch handling
    this.touchStartX = 0;
    this.touchEndX = 0;
    this.touchStartY = 0;
    this.touchEndY = 0;
    this.swipeThreshold = 50;
    
    // Animation timing
    this.transitionDuration = 400; // ms
    this.easing = 'cubic-bezier(0.4, 0, 0.2, 1)';
    
    // DOM element caches
    this.elements = {};
    
    // Node state for interactive architecture diagram
    this.expandedNodes = new Set();
    
    // Initialize
    this.init();
  }

  /**
   * Initialize the presentation controller
   */
  init() {
    this.cacheElements();
    this.bindEvents();
    this.injectControlPanel();
    this.loadFromHash();
    this.updateSlideClasses();
    this.updateProgress();
    this.updateHash();
    this.initArchitectureDiagram();
    
    // Log initialization
    console.log('%c🎯 Delta Crown Presentation Loaded', 'color: #4F46E5; font-size: 14px; font-weight: bold;');
    console.log(`%c   Current slide: ${this.currentSlide + 1}/${this.totalSlides}`, 'color: #6B7280;');
    console.log(`%c   Keyboard shortcuts: ← → or Space to navigate, F for fullscreen, O for overview, Esc to exit`, 'color: #6B7280;');
  }

  /**
   * Cache DOM elements for performance
   */
  cacheElements() {
    this.elements = {
      slides: document.querySelectorAll('.slide'),
      body: document.body,
      progressBar: null, // Will be set after injection
      progressText: null,
      prevBtn: null,
      nextBtn: null,
      fullscreenBtn: null,
      overviewBtn: null,
      controls: null
    };
    
    // Update total slides based on actual DOM elements if available
    if (this.elements.slides.length > 0) {
      this.totalSlides = this.elements.slides.length;
    }
  }

  /**
   * Bind all event listeners
   */
  bindEvents() {
    // Keyboard navigation
    document.addEventListener('keydown', (e) => this.handleKeyDown(e));
    
    // Touch/Swipe support for mobile
    document.addEventListener('touchstart', (e) => this.handleTouchStart(e), { passive: true });
    document.addEventListener('touchend', (e) => this.handleTouchEnd(e), { passive: true });
    
    // Prevent context menu on long press during presentation
    document.addEventListener('contextmenu', (e) => {
      if (this.isFullscreen) e.preventDefault();
    });
    
    // Handle fullscreen change events (from browser UI)
    document.addEventListener('fullscreenchange', () => this.handleFullscreenChange());
    document.addEventListener('webkitfullscreenchange', () => this.handleFullscreenChange());
    document.addEventListener('mozfullscreenchange', () => this.handleFullscreenChange());
    document.addEventListener('MSFullscreenChange', () => this.handleFullscreenChange());
    
    // Handle hash changes (back/forward buttons)
    window.addEventListener('hashchange', () => this.loadFromHash());
    
    // Handle window resize for responsive adjustments
    window.addEventListener('resize', () => this.handleResize());
  }

  /**
   * Inject control panel UI if not already present in HTML
   */
  injectControlPanel() {
    // Check if controls already exist
    if (document.querySelector('.presentation-controls')) {
      this.cacheControlElements();
      return;
    }
    
    const controlsHTML = `
      <div class="presentation-controls" id="presentation-controls">
        <div class="controls-main">
          <button class="control-btn" id="prev-btn" title="Previous Slide (←)">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="15 18 9 12 15 6"></polyline>
            </svg>
          </button>
          
          <span class="slide-counter" id="slide-counter">1 / ${this.totalSlides}</span>
          
          <button class="control-btn" id="next-btn" title="Next Slide (→ or Space)">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <polyline points="9 18 15 12 9 6"></polyline>
            </svg>
          </button>
        </div>
        
        <div class="controls-secondary">
          <button class="control-btn" id="overview-btn" title="Overview Mode (O)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <rect x="3" y="3" width="7" height="7"></rect>
              <rect x="14" y="3" width="7" height="7"></rect>
              <rect x="14" y="14" width="7" height="7"></rect>
              <rect x="3" y="14" width="7" height="7"></rect>
            </svg>
          </button>
          
          <button class="control-btn" id="fullscreen-btn" title="Toggle Fullscreen (F)">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" id="fullscreen-icon">
              <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"></path>
            </svg>
          </button>
        </div>
        
        <div class="progress-container">
          <div class="progress-bar" id="progress-bar" style="width: 0%"></div>
        </div>
      </div>
    `;
    
    // Insert controls at end of body
    const controlsContainer = document.createElement('div');
    controlsContainer.innerHTML = controlsHTML;
    document.body.appendChild(controlsContainer.firstElementChild);
    
    this.cacheControlElements();
    this.bindControlEvents();
  }

  /**
   * Cache control panel elements after injection
   */
  cacheControlElements() {
    this.elements.progressBar = document.getElementById('progress-bar');
    this.elements.progressText = document.getElementById('slide-counter');
    this.elements.prevBtn = document.getElementById('prev-btn');
    this.elements.nextBtn = document.getElementById('next-btn');
    this.elements.fullscreenBtn = document.getElementById('fullscreen-btn');
    this.elements.overviewBtn = document.getElementById('overview-btn');
    this.elements.controls = document.getElementById('presentation-controls');
  }

  /**
   * Bind events to control panel buttons
   */
  bindControlEvents() {
    if (this.elements.prevBtn) {
      this.elements.prevBtn.addEventListener('click', () => this.prevSlide());
    }
    if (this.elements.nextBtn) {
      this.elements.nextBtn.addEventListener('click', () => this.nextSlide());
    }
    if (this.elements.fullscreenBtn) {
      this.elements.fullscreenBtn.addEventListener('click', () => this.toggleFullscreen());
    }
    if (this.elements.overviewBtn) {
      this.elements.overviewBtn.addEventListener('click', () => this.toggleOverview());
    }
  }

  // ==================== NAVIGATION ====================

  /**
   * Navigate to next slide
   */
  nextSlide() {
    if (this.currentSlide < this.totalSlides - 1) {
      this.goToSlide(this.currentSlide + 1);
    } else {
      // Optional: visual feedback at end
      this.pulseControls();
    }
  }

  /**
   * Navigate to previous slide
   */
  prevSlide() {
    if (this.currentSlide > 0) {
      this.goToSlide(this.currentSlide - 1);
    } else {
      // Optional: visual feedback at start
      this.pulseControls();
    }
  }

  /**
   * Navigate to specific slide
   * @param {number} n - Slide index (0-based)
   */
  goToSlide(n) {
    // Validate slide index
    if (n < 0 || n >= this.totalSlides) {
      console.warn(`Invalid slide index: ${n}`);
      return;
    }
    
    // Determine direction for animation
    const direction = n > this.currentSlide ? 'next' : 'prev';
    
    // Update current slide
    this.currentSlide = n;
    
    // Update visuals
    this.updateSlideClasses(direction);
    this.updateProgress();
    this.updateHash();
    
    // Scroll to top of slide
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  // ==================== SLIDE VISUALS ====================

  /**
   * Update slide CSS classes for transitions
   * @param {string} direction - 'next', 'prev', or null for initial load
   */
  updateSlideClasses(direction = null) {
    if (!this.elements.slides.length) return;
    
    this.elements.slides.forEach((slide, index) => {
      // Reset classes
      slide.classList.remove(
        'slide-active',
        'slide-prev',
        'slide-next',
        'slide-in-right',
        'slide-in-left',
        'fade-in'
      );
      
      // Set appropriate state classes
      if (index === this.currentSlide) {
        slide.classList.add('slide-active');
        
        // Add animation class based on direction
        if (direction === 'next') {
          slide.classList.add('slide-in-right');
        } else if (direction === 'prev') {
          slide.classList.add('slide-in-left');
        } else {
          slide.classList.add('fade-in');
        }
      } else if (index < this.currentSlide) {
        slide.classList.add('slide-prev');
      } else {
        slide.classList.add('slide-next');
      }
    });
  }

  /**
   * Update progress bar and counter
   */
  updateProgress() {
    const progress = ((this.currentSlide + 1) / this.totalSlides) * 100;
    
    // Update progress bar
    if (this.elements.progressBar) {
      this.elements.progressBar.style.width = `${progress}%`;
    }
    
    // Update text counter
    if (this.elements.progressText) {
      this.elements.progressText.textContent = `${this.currentSlide + 1} / ${this.totalSlides}`;
    }
    
    // Update button states
    if (this.elements.prevBtn) {
      this.elements.prevBtn.disabled = this.currentSlide === 0;
      this.elements.prevBtn.style.opacity = this.currentSlide === 0 ? '0.3' : '1';
    }
    if (this.elements.nextBtn) {
      this.elements.nextBtn.disabled = this.currentSlide === this.totalSlides - 1;
      this.elements.nextBtn.style.opacity = this.currentSlide === this.totalSlides - 1 ? '0.3' : '1';
    }
  }

  /**
   * Update URL hash for direct linking
   */
  updateHash() {
    const newHash = `#slide-${this.currentSlide + 1}`;
    if (window.location.hash !== newHash) {
      history.replaceState(null, null, newHash);
    }
  }

  /**
   * Load starting slide from URL hash
   */
  loadFromHash() {
    const hash = window.location.hash;
    const match = hash.match(/#slide-(\d+)/);
    
    if (match) {
      const slideNum = parseInt(match[1], 10) - 1; // Convert to 0-based
      if (slideNum >= 0 && slideNum < this.totalSlides) {
        this.currentSlide = slideNum;
        this.updateSlideClasses();
        this.updateProgress();
      }
    }
  }

  // ==================== KEYBOARD HANDLING ====================

  /**
   * Handle keyboard events
   * @param {KeyboardEvent} e 
   */
  handleKeyDown(e) {
    // Don't handle if user is typing in an input
    if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') {
      return;
    }
    
    switch (e.key) {
      case 'ArrowRight':
      case ' ':
      case 'PageDown':
        e.preventDefault();
        this.nextSlide();
        break;
        
      case 'ArrowLeft':
      case 'PageUp':
        e.preventDefault();
        this.prevSlide();
        break;
        
      case 'Home':
        e.preventDefault();
        this.goToSlide(0);
        break;
        
      case 'End':
        e.preventDefault();
        this.goToSlide(this.totalSlides - 1);
        break;
        
      case 'f':
      case 'F':
        e.preventDefault();
        this.toggleFullscreen();
        break;
        
      case 'o':
      case 'O':
        e.preventDefault();
        this.toggleOverview();
        break;
        
      case 'Escape':
        e.preventDefault();
        if (this.isOverview) {
          this.toggleOverview();
        } else if (this.isFullscreen) {
          this.exitFullscreen();
        }
        break;
    }
  }

  // ==================== TOUCH/SWIPE HANDLING ====================

  /**
   * Handle touch start event
   * @param {TouchEvent} e 
   */
  handleTouchStart(e) {
    this.touchStartX = e.changedTouches[0].screenX;
    this.touchStartY = e.changedTouches[0].screenY;
  }

  /**
   * Handle touch end event and detect swipe
   * @param {TouchEvent} e 
   */
  handleTouchEnd(e) {
    this.touchEndX = e.changedTouches[0].screenX;
    this.touchEndY = e.changedTouches[0].screenY;
    
    this.handleSwipe();
  }

  /**
   * Calculate swipe direction and navigate
   */
  handleSwipe() {
    const diffX = this.touchStartX - this.touchEndX;
    const diffY = this.touchStartY - this.touchEndY;
    
    // Only handle horizontal swipes (ignore vertical scrolling)
    if (Math.abs(diffX) > Math.abs(diffY)) {
      if (Math.abs(diffX) > this.swipeThreshold) {
        if (diffX > 0) {
          // Swipe left -> next slide
          this.nextSlide();
        } else {
          // Swipe right -> previous slide
          this.prevSlide();
        }
      }
    }
  }

  // ==================== FULLSCREEN MODE ====================

  /**
   * Toggle fullscreen mode
   */
  toggleFullscreen() {
    if (this.isFullscreen) {
      this.exitFullscreen();
    } else {
      this.enterFullscreen();
    }
  }

  /**
   * Enter fullscreen mode
   */
  enterFullscreen() {
    const elem = document.documentElement;
    
    if (elem.requestFullscreen) {
      elem.requestFullscreen();
    } else if (elem.webkitRequestFullscreen) {
      elem.webkitRequestFullscreen();
    } else if (elem.mozRequestFullScreen) {
      elem.mozRequestFullScreen();
    } else if (elem.msRequestFullscreen) {
      elem.msRequestFullscreen();
    }
    
    this.elements.body.classList.add('fullscreen-mode');
    this.isFullscreen = true;
    this.updateFullscreenIcon();
  }

  /**
   * Exit fullscreen mode
   */
  exitFullscreen() {
    if (document.exitFullscreen) {
      document.exitFullscreen();
    } else if (document.webkitExitFullscreen) {
      document.webkitExitFullscreen();
    } else if (document.mozCancelFullScreen) {
      document.mozCancelFullScreen();
    } else if (document.msExitFullscreen) {
      document.msExitFullscreen();
    }
    
    this.elements.body.classList.remove('fullscreen-mode');
    this.isFullscreen = false;
    this.updateFullscreenIcon();
  }

  /**
   * Handle fullscreen change events from browser
   */
  handleFullscreenChange() {
    this.isFullscreen = !!(
      document.fullscreenElement ||
      document.webkitFullscreenElement ||
      document.mozFullScreenElement ||
      document.msFullscreenElement
    );
    
    if (this.isFullscreen) {
      this.elements.body.classList.add('fullscreen-mode');
    } else {
      this.elements.body.classList.remove('fullscreen-mode');
    }
    
    this.updateFullscreenIcon();
  }

  /**
   * Update fullscreen button icon
   */
  updateFullscreenIcon() {
    const icon = document.getElementById('fullscreen-icon');
    if (!icon) return;
    
    if (this.isFullscreen) {
      // Exit fullscreen icon
      icon.innerHTML = '<path d="M8 3v3a2 2 0 0 1-2 2H3m18 0h-3a2 2 0 0 1-2-2V3m0 18v-3a2 2 0 0 1 2-2h3M3 16h3a2 2 0 0 1 2 2v3"></path>';
    } else {
      // Enter fullscreen icon
      icon.innerHTML = '<path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"></path>';
    }
  }

  // ==================== OVERVIEW MODE ====================

  /**
   * Toggle overview mode (thumbnail grid)
   */
  toggleOverview() {
    if (this.isOverview) {
      this.exitOverview();
    } else {
      this.enterOverview();
    }
  }

  /**
   * Enter overview mode
   */
  enterOverview() {
    this.isOverview = true;
    this.elements.body.classList.add('overview-mode');
    
    // Create overview grid if not exists
    if (!document.getElementById('overview-grid')) {
      this.createOverviewGrid();
    }
    
    // Show overview
    const grid = document.getElementById('overview-grid');
    if (grid) {
      grid.style.display = 'grid';
      this.updateOverviewHighlight();
    }
  }

  /**
   * Exit overview mode
   */
  exitOverview() {
    this.isOverview = false;
    this.elements.body.classList.remove('overview-mode');
    
    const grid = document.getElementById('overview-grid');
    if (grid) {
      grid.style.display = 'none';
    }
  }

  /**
   * Create overview grid with slide thumbnails
   */
  createOverviewGrid() {
    const grid = document.createElement('div');
    grid.id = 'overview-grid';
    grid.className = 'overview-grid';
    
    this.elements.slides.forEach((slide, index) => {
      const thumb = document.createElement('div');
      thumb.className = 'overview-thumb';
      thumb.dataset.slide = index;
      
      // Create mini version of slide content
      const slideTitle = slide.querySelector('h1, h2, h3')?.textContent || `Slide ${index + 1}`;
      thumb.innerHTML = `
        <div class="thumb-number">${index + 1}</div>
        <div class="thumb-content">${slideTitle}</div>
      `;
      
      thumb.addEventListener('click', () => {
        this.goToSlide(index);
        this.exitOverview();
      });
      
      grid.appendChild(thumb);
    });
    
    document.body.appendChild(grid);
  }

  /**
   * Highlight current slide in overview
   */
  updateOverviewHighlight() {
    const thumbs = document.querySelectorAll('.overview-thumb');
    thumbs.forEach((thumb, index) => {
      thumb.classList.toggle('active', index === this.currentSlide);
    });
  }

  // ==================== INTERACTIVE ARCHITECTURE DIAGRAM ====================

  /**
   * Toggle node details in architecture diagram
   * @param {string} nodeId - The ID of the node to toggle
   */
  toggleNodeDetails(nodeId) {
    const node = document.getElementById(nodeId);
    if (!node) {
      console.warn(`Node not found: ${nodeId}`);
      return;
    }
    
    const details = node.querySelector('.node-details');
    if (!details) {
      console.warn(`No details found for node: ${nodeId}`);
      return;
    }
    
    const isExpanded = this.expandedNodes.has(nodeId);
    
    if (isExpanded) {
      // Collapse
      this.expandedNodes.delete(nodeId);
      node.classList.remove('node-expanded');
      details.style.maxHeight = '0';
      details.style.opacity = '0';
    } else {
      // Expand
      this.expandedNodes.add(nodeId);
      node.classList.add('node-expanded');
      details.style.maxHeight = details.scrollHeight + 'px';
      details.style.opacity = '1';
    }
  }

  /**
   * Initialize architecture diagram interactivity
   * Call this after DOM is ready if diagram exists
   */
  initArchitectureDiagram() {
    const diagram = document.getElementById('architecture-diagram');
    if (!diagram) return;
    
    // Map of node IDs to their details
    const nodeMap = {
      'node-htt-brands': {
        title: 'HTT Brands Tenant',
        description: 'Source tenant with existing users and groups',
        details: 'Contains all HTT Brands employees and their mailboxes. Cross-tenant sync will replicate selected users to DCE tenant.'
      },
      'node-cross-tenant': {
        title: 'Cross-Tenant Sync',
        description: 'Bidirectional synchronization bridge',
        details: 'Uses Microsoft Entra Cross-Tenant Synchronization to keep user identities in sync between tenants.'
      },
      'node-dce-tenant': {
        title: 'DCE Tenant',
        description: 'Target tenant for shared resources',
        details: 'New tenant where shared mailboxes and collaborative resources will be hosted.'
      },
      'node-shared-mailboxes': {
        title: 'Shared Mailboxes',
        description: 'Collaborative email solution',
        details: 'Shared mailboxes for departments like Marketing, Sales, and Operations accessible by both tenant users.'
      }
    };
    
    // Add click handlers to nodes
    Object.keys(nodeMap).forEach(nodeId => {
      const node = document.getElementById(nodeId);
      if (node) {
        node.style.cursor = 'pointer';
        node.addEventListener('click', () => this.toggleNodeDetails(nodeId));
        
        // Add hover tooltip
        node.title = 'Click to expand details';
      }
    });
  }

  // ==================== UTILITY METHODS ====================

  /**
   * Visual pulse feedback for controls (at boundaries)
   */
  pulseControls() {
    if (this.elements.controls) {
      this.elements.controls.classList.add('pulse');
      setTimeout(() => {
        this.elements.controls?.classList.remove('pulse');
      }, 300);
    }
  }

  /**
   * Handle window resize
   */
  handleResize() {
    // Recalculate any responsive layout if needed
    if (this.isOverview) {
      this.updateOverviewHighlight();
    }
  }

  /**
   * Get current presentation state
   * @returns {Object} Current state
   */
  getState() {
    return {
      currentSlide: this.currentSlide,
      totalSlides: this.totalSlides,
      isFullscreen: this.isFullscreen,
      isOverview: this.isOverview,
      progress: Math.round(((this.currentSlide + 1) / this.totalSlides) * 100)
    };
  }

  /**
   * Jump to specific slide by number (1-based for public API)
   * @param {number} slideNum - Slide number (1-based)
   */
  jumpTo(slideNum) {
    this.goToSlide(slideNum - 1);
  }
}

// ==================== INITIALIZATION ====================

document.addEventListener('DOMContentLoaded', () => {
  // Create global instance
  window.presentation = new PresentationController();
  
  // Expose for debugging
  window.presentationCtrl = window.presentation;
});

// ==================== EXPORT (for module systems) ====================

if (typeof module !== 'undefined' && module.exports) {
  module.exports = PresentationController;
}
