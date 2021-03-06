# this code is totally extracted from shoulda-matchers gem.
module Mongoid
  module Matchers
    class AllowMassAssignmentOfMatcher # :nodoc:
      attr_reader :failure_message, :negative_failure_message
      alias failure_message_when_negated negative_failure_message

      def initialize(attribute)
        @attribute = attribute.to_s
        @options = {}
      end

      def as(role)
        if active_model_less_than_3_1?
          raise 'You can specify role only in Rails 3.1 or greater'
        end
        @options[:role] = role
        self
      end

      def matches?(klass)
        @klass = klass
        if attr_mass_assignable?
          if whitelisting?
            @negative_failure_message = "#{@attribute} was made accessible"
          else
            if protected_attributes.empty?
              @negative_failure_message = 'no attributes were protected'
            else
              @negative_failure_message = "#{class_name} is protecting " \
                                          "#{protected_attributes.to_a.to_sentence}, " \
                                          "but not #{@attribute}."
            end
          end
          true
        else
          @failure_message = if whitelisting?
                               "Expected #{@attribute} to be accessible"
                             else
                               "Did not expect #{@attribute} to be protected"
                             end
          false
        end
      end

      def description
        "allow mass assignment of #{@attribute}"
      end

      private

      def role
        @options[:role] || :default
      end

      def protected_attributes
        @protected_attributes ||= (@klass.class.protected_attributes || [])
      end

      def accessible_attributes
        @accessible_attributes ||= (@klass.class.accessible_attributes || [])
      end

      def whitelisting?
        authorizer.is_a?(::ActiveModel::MassAssignmentSecurity::WhiteList)
      end

      def attr_mass_assignable?
        !authorizer.deny?(@attribute)
      end

      def authorizer
        if active_model_less_than_3_1?
          @klass.class.active_authorizer
        else
          @klass.class.active_authorizer[role]
        end
      end

      def class_name
        @klass.class.name
      end

      def active_model_less_than_3_1?
        ::ActiveModel::VERSION::STRING.to_f < 3.1
      end
    end

    # Ensures that the attribute can be set on mass update.
    #
    #   it { should_not allow_mass_assignment_of(:password) }
    #   it { should allow_mass_assignment_of(:first_name) }
    #
    # In Rails 3.1 you can check role as well:
    #
    #   it { should allow_mass_assignment_of(:first_name).as(:admin) }
    #
    def allow_mass_assignment_of(value)
      AllowMassAssignmentOfMatcher.new(value)
    end
  end
end
