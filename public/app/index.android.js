/**
  Blackletter for android
*/

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

import Root from './components/root.js';

export default class app extends Component {
  render() {
    return (
      <Root />
    );
  }
}

AppRegistry.registerComponent('app', () => app);
