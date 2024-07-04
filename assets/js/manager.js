import { tns } from "tiny-slider";

export class Manager {
  constructor(context) {
    this.context = context;
    this.currentPage = parseInt(context.el.dataset.currentPage);
    this.maxPage = parseInt(context.el.dataset.maxPage);
  }

  init() {
    this.context.handleEvent("page-manage", (data) => {
      var el = document.getElementById("slide-preview-" + data.current_page);

      if (el) {
        setTimeout(
          () => {
            const slidesLayout = document.getElementById("slides-layout");
            const layoutWidth = slidesLayout.clientWidth;
            const elementWidth = el.children[0].scrollWidth;
            const scrollPosition =
              el.children[0].offsetLeft - layoutWidth / 2 + elementWidth / 2;

            slidesLayout.scrollTo({
              left: scrollPosition,
              behavior: "smooth",
            });
          },
          data.timeout ? data.timeout : 0
        );
      }
    });

    window.addEventListener("keydown", (e) => {
      if ((e.target.tagName || "").toLowerCase() != "input") {
        e.preventDefault();

        switch (e.key) {
          case "ArrowUp":
            this.prevPage();
            break;
          case "ArrowLeft":
            this.prevPage();
            break;
          case "ArrowRight":
            this.nextPage();
            break;
          case "ArrowDown":
            this.nextPage();
            break;
        }
      }
    });

    this.initPreview();
  }

  initPreview() {
    var preview = document.getElementById("preview");

    if (preview) {
      let isDragging = false;
      let startX, startY;

      preview.addEventListener("mousedown", (e) => {
        isDragging = true;
        startX = e.clientX - preview.offsetLeft;
        startY = e.clientY - preview.offsetTop;
      });

      document.addEventListener("mousemove", (e) => {
        if (!isDragging) return;

        const newX = e.clientX - startX;
        const newY = e.clientY - startY;

        preview.style.left = `${newX}px`;
        preview.style.top = `${newY}px`;
      });

      document.addEventListener("mouseup", () => {
        isDragging = false;

        const windowWidth = window.innerWidth;
        const windowHeight = window.innerHeight;
        const previewRect = preview.getBoundingClientRect();
        const padding = 20; // Add 20px padding

        let snapX, snapY;

        if (previewRect.left < windowWidth / 2) {
          snapX = padding;
        } else {
          snapX = windowWidth - previewRect.width - padding;
        }

        if (previewRect.top < windowHeight / 2) {
          snapY = padding;
        } else {
          snapY = windowHeight - previewRect.height - padding;
        }

        preview.style.transition = "left 0.3s ease-out, top 0.3s ease-out";
        preview.style.left = `${snapX}px`;
        preview.style.top = `${snapY}px`;

        // Remove the transition after it's complete
        setTimeout(() => {
          preview.style.transition = "";
        }, 300);
      });
    }
  }

  update() {
    this.currentPage = parseInt(this.context.el.dataset.currentPage);
    var el = document.getElementById("slide-preview-" + this.currentPage);

    if (el) {
      setTimeout(() => {
        const slidesLayout = document.getElementById("slides-layout");
        const layoutWidth = slidesLayout.clientWidth;
        const elementWidth = el.children[0].scrollWidth;
        const scrollPosition =
          el.children[0].offsetLeft - layoutWidth / 2 + elementWidth / 2;

        slidesLayout.scrollTo({
          left: scrollPosition,
          behavior: "smooth",
        });
      }, 50);
    }

    this.initPreview();
  }

  nextPage() {
    if (this.currentPage == this.maxPage - 1) return;

    this.currentPage += 1;
    this.context.pushEventTo(this.context.el, "current-page", {
      page: this.currentPage.toString(),
    });
  }

  prevPage() {
    if (this.currentPage == 0) return;

    this.currentPage -= 1;
    this.context.pushEventTo(this.context.el, "current-page", {
      page: this.currentPage.toString(),
    });
  }
}
