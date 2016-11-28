/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

export default class app extends Component {
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Million dollar idea #21 begins
        </Text>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
    fontWeight: '100',
    fontFamily: 'monospace',
  },
});

AppRegistry.registerComponent('app', () => app);
