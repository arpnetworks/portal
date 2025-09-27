Stripe Integration Documentation
=================================

This document outlines the main areas where Stripe is integrated into our Portal and describes the functionality in each area.

1. Webhook Processing
---------------------

**Files:**
- ``app/controllers/api/v1/stripe_controller.rb``
- ``app/models/stripe_event.rb``

**Purpose:** Handles incoming webhooks from Stripe to keep the application in sync with Stripe events.

**Key Events Processed:**
- Payment failures, refunds, and successful payments
- Setup intent creation/completion for new customer onboarding
- Invoice finalization and payment processing
- Subscription creation and payment method attachment

**Event Processing:** Events are queued for background processing via ``EventProcessorJob``.

**Supported Events:**
- ``charge.refunded``
- ``customer.subscription.created``
- ``invoice.finalized``
- ``invoice.paid``
- ``invoice.payment_action_required``
- ``invoice.payment_failed``
- ``payment_method.attached``
- ``setup_intent.succeeded``
- ``setup_intent.created``

2. Account & Customer Management
--------------------------------

**Files:**
- ``app/models/stripe_account.rb``
- ``app/models/account.rb``

**Purpose:** Syncs customer data between the application and Stripe.

**Functionality:**
- Links local accounts to Stripe customers via ``stripe_customer_id``
- Syncs account details (name, address) to Stripe when accounts are updated
- Background sync jobs triggered after account saves
- Account model includes ``after_save :sync`` callback

3. Subscription Management
--------------------------

**Files:**
- ``app/models/stripe_subscription.rb``

**Purpose:** Manages recurring billing subscriptions for services.

**Key Features:**
- Creates new subscriptions for customers
- Adds/removes services from existing subscriptions
- Handles quantity updates for subscription items
- Links services to Stripe price IDs and subscription item IDs
- Supports both new subscription creation and adding to existing subscriptions

**Key Methods:**
- ``add!(service, opts)`` - Adds service to subscription
- ``remove!(service, opts)`` - Removes service from subscription
- ``bootstrap!`` - Creates initial Stripe customer
- ``create_setup_intent!`` - Creates setup intent for payment method collection

4. Invoice & Payment Processing
-------------------------------

**Files:**
- ``app/models/stripe_invoice.rb``

**Purpose:** Handles invoice creation and payment tracking between Stripe and internal billing system.

**Functionality:**
- Creates local invoices from Stripe invoice data
- Processes line items and discounts
- Links Stripe invoices to internal invoice system via ``stripe_invoice_id``
- Handles payment recording and refund processing
- Supports manual invoice creation with quantity descriptions

**Key Methods:**
- ``create_for_account(account, invoice)`` - Creates invoice from Stripe data
- ``link_to_invoice(arp_invoice_id, invoice)`` - Links existing invoice to Stripe
- ``create_payment(account, invoice)`` - Records payment from Stripe
- ``process_refund(charge)`` - Handles refund processing

5. Payment Method Setup
-----------------------

**Files:**
- ``app/controllers/credit_cards_controller.rb``

**Purpose:** Handles customer payment method collection with dual system support.

**Features:**
- Creates Stripe setup intents for secure payment method collection
- Falls back to legacy credit card system for non-Stripe accounts
- Bootstraps Stripe customer accounts when needed
- Conditional rendering based on ``@account.in_stripe?``

**Flow:**
1. Check if account is set up for Stripe
2. If yes: Create setup intent and render Stripe-powered form
3. If no: Use legacy credit card collection system

6. Email Notifications
----------------------

**Files:**
- ``app/models/mailers/stripe.rb``

**Purpose:** Sends transactional emails for Stripe-related events.

**Email Types:**
- ``payment_failed(account, opts)`` - Payment failure notifications
- ``sales_receipt(invoice_id, opts)`` - Sales receipts for successful payments
- ``refund(account, amount, opts)`` - Refund confirmations

**Features:**
- Uses hosted invoice URLs from Stripe
- Includes proper BCC for internal tracking
- Configurable subject lines via globals.yml

7. Background Jobs
------------------

**Files:**
- ``app/jobs/stripe/account_sync_job.rb``
- ``app/jobs/stripe/event_processor_job.rb``

**Purpose:** Handles asynchronous processing of Stripe-related tasks.

**Jobs:**
- ``AccountSyncJob`` - Syncs account data to Stripe customer records
- ``EventProcessorJob`` - Processes incoming webhook events

8. Database Integration
-----------------------

**Migration Files:**
- ``db/migrate/20211206053311_add_stripe_customer_id_to_account.rb``
- ``db/migrate/20211207051234_create_stripe_events.rb``
- ``db/migrate/20211207104707_add_stripe_invoice_id_to_invoice.rb``
- ``db/migrate/20211218114742_add_stripe_payment_method_id_to_account.rb``
- ``db/migrate/20211229002759_add_stripe_price_id_to_service.rb``
- ``db/migrate/20211230022111_add_stripe_subscription_item_id_to_service.rb``
- ``db/migrate/20220101052124_add_stripe_quantity_to_service.rb``

**Stripe-related Fields:**
- ``stripe_customer_id`` on accounts - Links to Stripe customer
- ``stripe_invoice_id`` on invoices - Links to Stripe invoice
- ``stripe_payment_method_id`` on accounts - Default payment method
- ``stripe_price_id`` on services - Links to Stripe price
- ``stripe_subscription_item_id`` on services - Links to subscription item
- ``stripe_quantity`` on services - Quantity for billing

Architecture Overview
---------------------

The Portal has migrated from a legacy billing system to Stripe for payment processing. The integration supports:

- **Hybrid Billing System:** Both subscription billing for recurring services and one-time invoice payments
- **Migration Support:** Graceful transition from legacy credit card system to Stripe
- **Real-time Synchronization:** Comprehensive webhook handling for real-time updates
- **Service-based Billing:** Each service can be individually tracked and billed through Stripe subscriptions
- **Customer Management:** Automatic customer creation and synchronization

**Key Design Patterns:**
- Event-driven architecture using webhooks
- Background job processing for heavy operations
- Fallback mechanisms for legacy system compatibility
- Metadata linking between Stripe objects and internal models
