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
      // Load Stripe.js dynamically
      await loadScript('https://js.stripe.com/v3/');
      
      if (window.stripeConfig === undefined) {
        const stripe = Stripe(this.el.dataset.stripeKey);
        const elements = stripe.elements();
        const addressElement = elements.create("address", {
          mode: "billing",
          fields: {
            country: "US"
          }
        });
        const cardElement = elements.create("card");
        window.stripeConfig = { stripe, elements, addressElement, cardElement };
      }

      const paymentErrors = document.getElementById("payment-errors");
      const form = document.getElementById("payment-form");

      window.stripeConfig.addressElement.mount("#address-element");
      window.stripeConfig.cardElement.mount("#card-element");

      const clientSecret = this.el.dataset.clientSecret;

      form.addEventListener("submit", async (event) => {
        event.preventDefault();
        const billingDetails = await window.stripeConfig.addressElement.getValue();

        const { payment, error } = await window.stripeConfig.stripe.confirmCardPayment(clientSecret, {
          payment_method: {
            card: window.stripeConfig.cardElement,
            billing_details: billingDetails.value
          }
        });

        if (error) {
          paymentErrors.textContent = error.message;
          return;
        }

        window.location.href = "/sponsorships/success?payment_intent_id=" + this.el.dataset.paymentIntentId;
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
  }
}

export default Hooks; 