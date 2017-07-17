/** @babel */

/**
 * Copyright (c) 2016-present PlatformIO <contact@platformio.org>
 * All rights reserved.
 *
 * This source code is licensed under the license found in the LICENSE file in
 * the root directory of this source tree.
 */

import * as actions from '../actions';
import { BOARDS_INPUT_FILTER_KEY, getBoardsFilter, getVisibleBoards } from '../selectors';

import Boards from '../components/boards';
import { INPUT_FILTER_DELAY } from '../../config';
import PropTypes from 'prop-types';
import React from 'react';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { goTo } from '../../core/helpers';
import { lazyUpdateInputValue } from '../../core/actions';


class BoardsPage extends React.Component {

  static propTypes = {
    items: PropTypes.arrayOf(PropTypes.object),
    storageFilterValue: PropTypes.string.isRequired,
    setStorageFilter: PropTypes.func.isRequired,
    filterValue: PropTypes.string.isRequired,
    setFilter: PropTypes.func.isRequired,
    loadBoards: PropTypes.func.isRequired,
    showPlatform: PropTypes.func.isRequired,
    showFramework: PropTypes.func.isRequired
  }

  componentWillMount() {
    this.props.loadBoards();
  }

  render() {
    return (
      <section className='page-container-fluid boards-page'>
        <Boards
          items={ this.props.items }
          header='Board Explorer'
          defaultFilter={ this.props.filterValue }
          onFilter={ this.props.setFilter }
          showPlatform={ this.props.showPlatform }
          showFramework={ this.props.showFramework } />
      </section>
    );
  }

}

// Redux

function mapStateToProps(state, ownProps) {
  return {
    items: getVisibleBoards(state),
    filterValue: getBoardsFilter(state),
    showPlatform: name => goTo(ownProps.history, '/platform/embedded/show', { name }),
    showFramework: name => goTo(ownProps.history, '/platform/frameworks/show', { name })
  };
}

function mapDispatchToProps(dispatch) {
  return bindActionCreators(Object.assign({}, actions, {
    setFilter: value => dispatch(lazyUpdateInputValue(BOARDS_INPUT_FILTER_KEY, value, INPUT_FILTER_DELAY))
  }), dispatch);
}

function mergeProps(stateProps, dispatchProps) {
  return Object.assign({}, stateProps, dispatchProps);
}

export default connect(mapStateToProps, mapDispatchToProps, mergeProps)(BoardsPage);
