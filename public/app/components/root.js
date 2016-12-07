import React, { 
  Component, 
  PropTypes 
} from 'react';
import { 
  View, 
  Text, 
  Image, 
  StyleSheet 
} from 'react-native';

export default class Root extends Component {
  render() {
    return (
      <View style={styles.container}>
        <View style={styles.toolbar}>
          <View style={styles.toolbarLogoWrapper}>
            <Image source={require('../logo.png')} style={styles.toolbarLogo} />
          </View>
          <View style={styles.toolbarContent}>
            <Text style={styles.toolbarTitle}>
              Blackletter
            </Text>
          </View>
        </View>
        <View style={{flex:100}}>
          <Text style={styles.welcome}>
            Content could go here.
          </Text>
        </View>
      </View>
    )
  }
}

const route = {
  title: "Blackletter"
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'stretch',
    justifyContent: 'flex-start',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
    fontWeight: '100',
    fontFamily: 'roboto',
  },
  toolbar: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'space-between',
    backgroundColor: '#111',
    minHeight: 50
  },
  toolbarLogoWrapper: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  toolbarLogo: {
    width: 40, 
    height: 40, 
  },
  toolbarContent: {
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
  },
  toolbarTitle: {
    color: "#fff",
    fontSize: 24,
    fontFamily: 'sans-serif-thin',
  },
});

