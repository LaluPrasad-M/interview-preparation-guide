# The Card Payment Flow

> [!tldr]
> When the success screen appears, no money has moved. Your bank has only promised the merchant's bank it will send the money later, and frozen that amount in your account.

---

## The five players

1. **You**, the customer.
2. **The merchant**, the app or website you are buying from.
3. **The payment gateway and processor**, the secure digital cashier and router, such as Stripe or Razorpay.
4. **The card network**, the bridge, such as Visa, Mastercard or RuPay.
5. **The banks**, your bank called the issuing bank, and the merchant's bank called the acquiring bank.

---

## The two phases

When you hit pay, the flow happens in two completely separate phases. **Authorization** happens in a split second while you watch the spinner. **Settlement** happens quietly behind the scenes much later.

---

## Phase 1, authorization, step by step

**1. The checkout, initiation.** You enter your card details and click pay. The merchant does not want to touch or store your sensitive card numbers due to strict security rules, so they immediately hand that data to their payment gateway.

**2. The gateway encrypts the data, the security check.** The gateway securely packages your card details and the transaction amount, and sends the package to the payment processor. Often the gateway and the processor are the same company.

**3. The processor routes the request, the networker.** The processor looks at your card number, identifies the network, and forwards the request to it.

**4. The card network finds your bank, the bridge.** The network does not hold your money. It knows how to talk to every bank in the world, and routes the request to your issuing bank.

**5. Your bank decides, authorization.** Your bank runs quick checks: is this card valid, do you have enough money, does this look like fraud? It generates an approved or declined code. If approved, it puts a temporary hold on those funds so you cannot spend them twice.

**6. The return trip, confirmation.** Your bank sends the approved code backwards through the same chain: card network, processor, gateway, merchant.

**7. The success screen, completion.** The merchant's website receives the approved message and shows you payment successful.

---

## What has actually happened

At this exact moment, no money has moved. Your bank has promised the merchant's bank that it will send the money later, and it has frozen that amount in your account.

The actual movement of money, phase 2 settlement, usually happens in a big batch at the end of the day, where the banks settle all their IOUs with each other.
