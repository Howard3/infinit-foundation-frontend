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

const Hooks = {
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
  }
}

export default Hooks; 