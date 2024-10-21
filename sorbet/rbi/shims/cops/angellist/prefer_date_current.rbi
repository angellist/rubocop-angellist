# typed: strict

class RuboCop::Cop::Angellist::PreferDateCurrent
  sig { params(node: RuboCop::AST::Node).returns(T::Boolean) }
  def time_zone_today?(node); end
end
