const loadScript = (src) => {
  return new Promise((resolve, reject) => {
    if (document.querySelector(`script[src="${src}"]`)) {
      resolve();
      return;
    }
    const script = document.createElement('script');
    script.src = src;
    script.onload = resolve;
    script.onerror = reject;
    document.head.appendChild(script);
  });
};

// waitForClerk is a function that is used to wait for the Clerk library to be loaded.
const waitForClerk = () => {
  return new Promise((resolve) => {
    if (window.Clerk) {
          resolve();
          return;
        }
        const checkClerk = setInterval(() => {
          if (window.Clerk) {
            clearInterval(checkClerk);
            resolve();
          }
        }, 100);
  });
};

const Hooks = {
  // PostHogGlobal is a hook that is used to capture the pageview event.
  PostHogGlobal: {
    mounted() {
      posthog.capture("$pageview");
    },
    destroyed() {
      posthog.capture("$pageleave");
    },
  },

  // ClerkUserButton is a hook that is used to load the Clerk user button.
  // It is used to ensure that the Clerk user button is loaded after the page has loaded.
  ClerkUserButton: {
    async mounted() {
      await waitForClerk();
      await this.clerkLoaded();
    },

    async clerkLoaded() {
      await Clerk.load({
        afterSignOutUrl: "/sign-out"
      });
      const userControl = document.getElementById('user-control');
      const mobileUserControl = document.getElementById('mobile-top-user-control');
      const userControlContent = document.getElementById('user-control-content');
      const mobileUserControlContent = document.getElementById('mobile-top-user-control-content');
      if (Clerk.user) {
        userControlContent.innerHTML = '';
        mobileUserControlContent.innerHTML = '';
        await Clerk.mountUserButton(userControlContent, {afterSignOutUrl: "/sign-out"});
        await Clerk.mountUserButton(mobileUserControlContent, {afterSignOutUrl: "/sign-out"});

        posthog.identify(Clerk.user.id, {
          email: Clerk.user.primaryEmailAddress.emailAddress,
          name: Clerk.user.fullName
        });
      }

      userControl.classList.remove('hidden');
      mobileUserControl.classList.remove('hidden');
    }
  },

  ClerkSignIn: {
    async mounted() {
      await waitForClerk();
      await this.clerkLoaded();
    },

    async clerkLoaded() {
      await Clerk.load({});
      const signIn = document.getElementById('sign-in'); 
      await Clerk.mountSignIn(signIn, { forceRedirectUrl: '/sign-in-callback' });
    }
  },

  Payments: {
    async mounted() {
        await this.pushEvent("load_payments", {});
    }
  },
  StripeForm: {
    async mounted() {
      const clientSecret = this.el.dataset.clientSecret;
      let elements;
      // Load Stripe.js dynamically
      await loadScript('https://js.stripe.com/v3/');
      
      if (window.stripeConfig === undefined) {
        const stripe = Stripe(this.el.dataset.stripeKey);
        elements = stripe.elements({clientSecret: this.el.dataset.clientSecret});
        const addressElement = elements.create("address", {
          mode: "billing",
          fields: {
            country: "US"
          }
        });
        const cardElement = elements.create("payment", {
          layout: "accordion",
          defaultCollapsed: true,
          radios: true,
          spacedAccordionItems: false
        });
        window.stripeConfig = { stripe, elements, addressElement, cardElement };
      }

      const paymentErrors = document.getElementById("payment-errors");
      const form = document.getElementById("payment-form");

      window.stripeConfig.addressElement.mount("#address-element");
      window.stripeConfig.cardElement.mount("#payment-element");

      form.addEventListener("submit", async (event) => {
        event.preventDefault();

        if (!window.stripeConfig.stripe) {
          console.error("Stripe is not loaded");
          return;
        }

          // Trigger form validation and wallet collection
        const {error: submitError} = await elements.submit();
        if (submitError) {
          paymentErrors.textContent = submitError.message;
          return;
        }

        const billingDetails = await window.stripeConfig.addressElement.getValue();

        const { payment, error } = await window.stripeConfig.stripe.confirmPayment({
          elements,
          clientSecret,
          confirmParams: {
            return_url: window.location.origin + "/sponsorships/success?payment_intent_id=" + this.el.dataset.paymentIntentId
          },
        });

        if (error) {
          paymentErrors.textContent = error.message;
          return;
        }
      });
    }
  },

  CountdownTimer: {
    mounted() {
      const minutes = parseInt(this.el.dataset.minutes);
      let totalSeconds = minutes * 60;
      
      this.timer = setInterval(() => {
        totalSeconds--;
        
        if (totalSeconds <= 0) {
          clearInterval(this.timer);
          window.location.href = "/students";
          return;
        }

        const minutesRemaining = Math.floor(totalSeconds / 60);
        const secondsRemaining = totalSeconds % 60;
        
        this.el.textContent = `${minutesRemaining}:${secondsRemaining.toString().padStart(2, '0')}`;
        
        // Add warning colors when time is running low
        if (totalSeconds < 60) {
          this.el.classList.add('animate-pulse');
        }
      }, 1000);
    },

    destroyed() {
      if (this.timer) {
        clearInterval(this.timer);
      }
    }
  },

  // Add the Responsive hook directly here
  Responsive: {
    mounted() {
      this.handleResize = () => {
        const isMobile = window.innerWidth < 768; // md breakpoint
        const isTablet = window.innerWidth >= 768 && window.innerWidth < 1024; // between md and lg
        const perPage = isMobile ? 1 : (isTablet ? 2 : 3);
        
        this.pushEvent("viewport-changed", { perPage });
      };

      window.addEventListener("resize", this.handleResize);
      // Initial check
      this.handleResize();
    },

    destroyed() {
      window.removeEventListener("resize", this.handleResize);
    }
  },

  FeedingChart: {
    mounted() {
      this.createChart();
    },

    updated() {
      // Clear existing chart before redrawing
      d3.select(this.el).selectAll("*").remove();
      this.createChart();
    },

    destroyed() {
      d3.select(this.el).selectAll("*").remove();
    },

    createChart() {
      const container = this.el;  // Store reference to container
      const data = JSON.parse(container.dataset.counts).map((count, i) => ({
        date: new Date(JSON.parse(container.dataset.dates)[i]),
        value: count
      }));

      // Set dimensions and margins
      const margin = { top: 20, right: 30, bottom: 30, left: 50 };  // Increased left margin
      const width = container.offsetWidth - margin.left - margin.right;
      const height = container.offsetHeight - margin.top - margin.bottom;

      // Create SVG container
      const svg = d3.select(container)
        .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", `translate(${margin.left},${margin.top})`);

      // Create scales
      const x = d3.scaleTime()
        .domain(d3.extent(data, d => d.date))
        .range([0, width]);

      const y = d3.scaleLinear()
        .domain([0, d3.max(data, d => d.value)])
        .nice()
        .range([height, 0]);

      // Create line generator
      const line = d3.line()
        .x(d => x(d.date))
        .y(d => y(d.value))
        .curve(d3.curveMonotoneX);

      // Create area generator for fill
      const area = d3.area()
        .x(d => x(d.date))
        .y0(height)
        .y1(d => y(d.value))
        .curve(d3.curveMonotoneX);

      // Add the area fill
      svg.append("path")
        .datum(data)
        .attr("fill", "rgba(220, 38, 38, 0.1)")
        .attr("d", area);

      // Add the line path
      svg.append("path")
        .datum(data)
        .attr("fill", "none")
        .attr("stroke", "rgb(220, 38, 38)")
        .attr("stroke-width", 2)
        .attr("d", line)
        .attr("class", "line");

      // Add axes
      svg.append("g")
        .attr("transform", `translate(0,${height})`)
        .call(d3.axisBottom(x)
          .ticks(width > 600 ? 10 : 5)
          .tickFormat(d3.timeFormat("%b %d")))
        .call(g => g.select(".domain").attr("stroke-opacity", 0.2))
        .call(g => g.selectAll(".tick line").attr("stroke-opacity", 0.2));

      // Remove the left axis and add value labels directly on the grid lines
      svg.append("g")
        .selectAll("line")
        .data(y.ticks(5))
        .join("line")
        .attr("x1", 0)
        .attr("x2", width)
        .attr("y1", d => y(d))
        .attr("y2", d => y(d))
        .attr("stroke", "#e5e7eb")  // gray-200
        .attr("stroke-opacity", 0.5);

      // Add value labels on the left
      svg.append("g")
        .selectAll("text")
        .data(y.ticks(5))
        .join("text")
        .attr("x", -8)  // Move labels to the left of the line
        .attr("y", d => y(d))
        .attr("dy", "0.32em")
        .attr("fill", "#6B7280")  // gray-500
        .attr("font-size", "12px")
        .attr("text-anchor", "end")  // Right-align text
        .text(d => d);

      // Add "Total Meals" label - vertical and to the right of value labels
      svg.append("text")
        .attr("x", -25)  // Position to right of value labels
        .attr("y", height / 2)  // Center vertically
        .attr("transform", "rotate(-90, -25, " + (height / 2) + ")")  // Rotate around its position
        .attr("fill", "#6B7280")
        .attr("font-size", "12px")
        .attr("font-weight", "500")
        .attr("text-anchor", "middle")  // Center the text on its point
        .text("Total Meals");

      // Add hover effects
      const tooltip = d3.select(container)
        .append("div")
        .attr("class", "chart-tooltip")
        .style("position", "absolute")
        .style("visibility", "hidden")
        .style("background-color", "rgba(0, 0, 0, 0.8)")
        .style("color", "white")
        .style("padding", "8px")
        .style("border-radius", "4px")
        .style("font-size", "12px")
        .style("pointer-events", "none")
        .style("z-index", "10");

      const bisect = d3.bisector(d => d.date).left;

      svg.append("rect")
        .attr("width", width)
        .attr("height", height)
        .style("fill", "none")
        .style("pointer-events", "all")
        .on("mousemove", function(event) {
          const bounds = container.getBoundingClientRect();
          const [mouseX, mouseY] = d3.pointer(event, this);
          const x0 = x.invert(mouseX);
          const i = bisect(data, x0, 1);
          const d0 = data[i - 1];
          const d1 = data[i];
          const d = x0 - d0.date > d1.date - x0 ? d1 : d0;
          
          tooltip
            .style("visibility", "visible")
            .html(`Total Meals: ${d.value}<br>${d3.timeFormat("%B %d")(d.date)}`);
        })
        .on("mouseout", () => tooltip.style("visibility", "hidden"));
    }
  },

  ImageModal: {
    mounted() {
      const modal = document.getElementById('image-modal');
      const modalImg = document.getElementById('modal-image');

      window.addEventListener('show-image', (e) => {
        modalImg.src = e.detail.src;
        modal.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
      });

      // Handle click on the entire modal container
      modal.addEventListener('click', (e) => {
        // Close if clicking outside the image
        if (!e.target.closest('img')) {
          modal.classList.add('hidden');
          document.body.style.overflow = '';
        }
      });

      this.handleEvent("hide-modal", () => {
        modal.classList.add('hidden');
        document.body.style.overflow = '';
      });
    }
  }
}

export default Hooks; 