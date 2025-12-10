# frozen_string_literal: true
# typed: false

RSpec.describe RuboCop::Cop::Angellist::EnforceMethodCallSites, :config do
  let(:config) do
    RuboCop::Config.new(
      'Angellist/EnforceMethodCallSites' => {
        'Enabled' => true,
        'Restrictions' => restrictions,
      },
    )
  end

  let(:restrictions) do
    [
      {
        'Module' => 'Payment::Service',
        'Methods' => 'all',
        'AllowedCallSites' => [
          'app/models/payment.rb',
          'app/services/payment/service.rb',
        ],
      },
    ]
  end

  context 'with basic method calls' do
    it 'registers an offense for direct calls from non-allowed files' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            Payment::Service.process_payment(amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.process_payment can only be called from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end

    it 'does not register an offense for calls from allowed files' do
      expect_no_offenses(<<~RUBY, 'app/models/payment.rb')
        class Payment
          def process
            Payment::Service.process_payment(amount)
          end
        end
      RUBY
    end

    it 'registers an offense for safe navigation calls from non-allowed files' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            Payment::Service&.process_payment(amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.process_payment can only be called from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end

    it 'registers an offense for fully qualified calls from non-allowed files' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            ::Payment::Service.process_payment(amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ::Payment::Service.process_payment can only be called from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end
  end

  context 'with variable assignments' do
    it 'registers an offense for local variable assignments' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            service = Payment::Service
            service.process_payment(amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ service.process_payment can only be called from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end

    it 'registers an offense for instance variable assignments' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def initialize
            @service = Payment::Service
          end

          def process
            @service.process_payment(amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ @service.process_payment can only be called from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end
  end

  context 'with dynamic sends' do
    it 'registers an offense for send calls' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            Payment::Service.send(:process_payment, amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dynamic call to Payment::Service.process_payment can only be made from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end

    it 'registers an offense for public_send calls' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            Payment::Service.public_send(:process_payment, amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dynamic call to Payment::Service.process_payment can only be made from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end

    it 'registers an offense for __send__ calls' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            Payment::Service.__send__(:process_payment, amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dynamic call to Payment::Service.process_payment can only be made from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end

    it 'registers an offense for dynamic send on variable' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            service = Payment::Service
            service.send(:process_payment, amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dynamic call to Payment::Service.process_payment can only be made from: app/models/payment.rb, app/services/payment/service.rb
          end
        end
      RUBY
    end
  end

  context 'with specific methods restriction' do
    let(:restrictions) do
      [
        {
          'Module' => 'Payment::Service',
          'Methods' => ['process_payment', 'refund'],
          'AllowedCallSites' => ['app/models/payment.rb'],
        }
      ]
    end

    it 'registers an offense for restricted methods' do
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            Payment::Service.process_payment(amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.process_payment can only be called from: app/models/payment.rb
            Payment::Service.refund(payment_id)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.refund can only be called from: app/models/payment.rb
          end
        end
      RUBY
    end

    it 'does not register an offense for non-restricted methods' do
      expect_no_offenses(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            Payment::Service.validate(payment)
            Payment::Service.log_activity(action)
          end
        end
      RUBY
    end
  end

  context 'with glob patterns in AllowedCallSites' do
    let(:restrictions) do
      [
        {
          'Module' => 'Payment::Service',
          'Methods' => 'all',
          'AllowedCallSites' => [
            'app/models/**/*.rb',
            'spec/**/*_spec.rb',
          ],
        },
      ]
    end

    it 'allows calls from files matching glob patterns' do
      expect_no_offenses(<<~RUBY, 'app/models/concerns/payment_concern.rb')
        module PaymentConcern
          def process
            Payment::Service.process_payment(amount)
          end
        end
      RUBY

      expect_no_offenses(<<~RUBY, 'spec/models/payment_spec.rb')
        describe Payment do
          it 'processes payment' do
            Payment::Service.process_payment(100)
          end
        end
      RUBY
    end

    it 'registers offense for files not matching patterns' do
      expect_offense(<<~RUBY, 'app/controllers/payment_controller.rb')
        class PaymentController
          def create
            Payment::Service.process_payment(amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.process_payment can only be called from: app/models/**/*.rb, spec/**/*_spec.rb
          end
        end
      RUBY
    end
  end

  context 'with multiple module restrictions' do
    let(:restrictions) do
      [
        {
          'Module' => 'Payment::Service',
          'Methods' => 'all',
          'AllowedCallSites' => ['app/models/payment.rb'],
        },
        {
          'Module' => 'Notification::Service',
          'Methods' => ['send_email'],
          'AllowedCallSites' => ['app/services/notification/**/*.rb'],
        },
      ]
    end

    it 'enforces restrictions for each module independently' do
      expect_offense(<<~RUBY, 'app/controllers/test_controller.rb')
        class TestController
          def process
            Payment::Service.process_payment(amount)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.process_payment can only be called from: app/models/payment.rb
            Notification::Service.send_email(user)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Notification::Service.send_email can only be called from: app/services/notification/**/*.rb
          end
        end
      RUBY
    end
  end

  context 'with different modules having same method names' do
    let(:restrictions) do
      [
        {
          'Module' => 'Payment::Service',
          'Methods' => ['process', 'validate'],
          'AllowedCallSites' => ['app/models/payment.rb'],
        },
        {
          'Module' => 'Order::Service',
          'Methods' => ['process', 'validate'],
          'AllowedCallSites' => ['app/models/order.rb'],
        },
      ]
    end

    it 'does not confuse different modules with same method names' do
      expect_offense(<<~RUBY, 'app/controllers/test_controller.rb')
        class TestController
          def run
            # Payment::Service.process should be flagged
            Payment::Service.process(payment_data)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.process can only be called from: app/models/payment.rb

            # Order::Service.process should also be flagged with its own restriction
            Order::Service.process(order_data)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order::Service.process can only be called from: app/models/order.rb

            # Different module, not restricted
            Shipping::Service.process(shipping_data) # Should not be flagged
          end
        end
      RUBY
    end

    it 'allows calls to the correct module from their respective allowed files' do
      expect_no_offenses(<<~RUBY, 'app/models/payment.rb')
        class Payment
          def handle
            Payment::Service.process(data) # Allowed in payment.rb
            Payment::Service.validate(data) # Allowed in payment.rb
            # Note: Order::Service would be flagged here - tested in next spec
          end
        end
      RUBY
    end

    it 'flags cross-module calls even from allowed files' do
      expect_offense(<<~RUBY, 'app/models/payment.rb')
        class Payment
          def handle
            Payment::Service.process(data) # OK - Payment::Service allowed in payment.rb
            Order::Service.process(order)  # Not OK - Order::Service not allowed here
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Order::Service.process can only be called from: app/models/order.rb
          end
        end
      RUBY
    end

    it 'handles dynamic sends for different modules correctly' do
      expect_offense(<<~RUBY, 'app/controllers/test_controller.rb')
        class TestController
          def run
            Payment::Service.send(:process, payment_data)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dynamic call to Payment::Service.process can only be made from: app/models/payment.rb
            Order::Service.send(:process, order_data)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Dynamic call to Order::Service.process can only be made from: app/models/order.rb
            Shipping::Service.send(:process, shipping_data) # Not restricted
          end
        end
      RUBY
    end
  end

  context 'with partial module name matches' do
    let(:restrictions) do
      [
        {
          'Module' => 'Service',
          'Methods' => ['execute'],
          'AllowedCallSites' => ['app/services/base_service.rb'],
        },
        {
          'Module' => 'Payment::Service',
          'Methods' => ['execute'],
          'AllowedCallSites' => ['app/models/payment.rb'],
        },
      ]
    end

    it 'does not confuse partial module name matches' do
      expect_offense(<<~RUBY, 'app/controllers/test_controller.rb')
        class TestController
          def run
            # Should match the more specific Payment::Service restriction
            Payment::Service.execute(data)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.execute can only be called from: app/models/payment.rb

            # Should match the generic Service restriction
            Service.execute(data)
            ^^^^^^^^^^^^^^^^^^^^^ Service.execute can only be called from: app/services/base_service.rb

            # Should not be flagged - different module
            Order::Service.execute(data)
          end
        end
      RUBY
    end
  end

  context 'with edge cases' do
    it 'tracks method references' do
      # Method references are now tracked
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            method_ref = Payment::Service.method(:process_payment)
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Method reference to Payment::Service.process_payment can only be made from: app/models/payment.rb, app/services/payment/service.rb
            method_ref.call(amount)
          end
        end
      RUBY
    end

    it 'tracks calls within procs/lambdas' do
      # Calls within procs/lambdas are properly tracked and flagged
      expect_offense(<<~RUBY, 'app/controllers/unauthorized_controller.rb')
        class UnauthorizedController
          def process
            callable = -> (amt) { Payment::Service.process_payment(amt) }
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Payment::Service.process_payment can only be called from: app/models/payment.rb, app/services/payment/service.rb
            callable.call(amount)
          end
        end
      RUBY
    end
  end
end
