#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { REGION } from '../utils/constants';
import { UsersStack } from '../lib/stacks/users';

const region = REGION
const env: cdk.Environment = { region }
const app = new cdk.App();
new UsersStack(app, 'users', { env });