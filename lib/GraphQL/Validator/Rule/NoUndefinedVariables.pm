package GraphQL::Validator::Rule::NoUndefinedVariables;

use strict;
use warnings;

use GraphQL::Error qw/GraphQLError/;

sub undefined_var_message {
    my ($var_name, $op_name) = @_;
    return $op_name
        ? qq`Variable "\$$var_name" is not defined by operation "$op_name".`
        : qq`Variable "\$$var_name" is not defined.`;
}

# No undefined variables
#
# A GraphQL operation is only valid if all variables encountered, both directly
# and via fragment spreads, are defined by that operation.
sub validate {
    my ($self, $context) = @_;
    my %variable_name_defined;

    return {
        OperationDefinition => {
            enter => sub {
                %variable_name_defined = ();
                return;
            },
            leave => sub {
                my (undef, $operation) = @_;
                my $usages = $context->get_recursive_variable_usages($operation);

                for my $u (@$usages) {
                    my $node = $u->{node};
                    my $var_name = $node->{name}{value};

                    if (!$variable_name_defined{ $var_name }) {
                        $context->report_error(
                            GraphQLError(
                                undefined_var_message(
                                    $var_name,
                                    $operation->{name} && $operation->{name}{value}
                                ),
                                [$node, $operation]
                            )
                        );
                    }
                }

                return; # void
            },
        },
        VariableDefinition => sub {
            my (undef, $node) = @_;
            $variable_name_defined{ $node->{variable}{name}{value} } = 1;
            return; # void
        },
    };
}

1;

__END__
