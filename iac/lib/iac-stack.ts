import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';
import { UsersStack } from './stacks/users';

export class IacStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

  }
}
