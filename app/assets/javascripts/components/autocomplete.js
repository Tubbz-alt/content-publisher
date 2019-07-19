//= require accessible-autocomplete/dist/accessible-autocomplete.min.js
window.GOVUK = window.GOVUK || {}
window.GOVUK.Modules = window.GOVUK.Modules || {};

(function (Modules) {
  function Autocomplete () { }

  Autocomplete.prototype.start = function ($module) {
    this.$module = $module[0]
    var type = this.$module.dataset.autocompleteType

    var $select = this.$module.querySelector('select')
    var $input = this.$module.querySelector('input')

    if (type === 'with-hint-on-options') {
      this.initAutoCompleteWithHintOnOptions()
    } else if (type === 'topics') {
      this.initAutoCompleteSearchTopics()
    } else if ($select) {
      this.initAutoCompleteSelect($select)
    } else if ($input) {
      this.initAutoCompleteInput($input)
    }
  }

  Autocomplete.prototype.initAutoCompleteSelect = function ($select) {
    // disabled eslint because we can not control the name of the constructor (expected to be EnhanceSelectElement)
    new window.accessibleAutocomplete.enhanceSelectElement({ // eslint-disable-line no-new, new-cap
      selectElement: $select,
      minLength: 3,
      showNoOptionsFound: true
    })
  }

  Autocomplete.prototype.initAutoCompleteWithHintOnOptions = function () {
    // Read options and associated data attributes and feed that as results for inputValueTemplate
    var $select = this.$module.querySelector('select')

    if (!$select) {
      return
    }

    var $options = $select.querySelectorAll('option')

    new window.accessibleAutocomplete({ // eslint-disable-line no-new, new-cap
      element: this.$module,
      id: $select.id,
      source: function (query, syncResults) {
        var results = []
        $options.forEach(function ($el) {
          results.push({text: $el.textContent, hint: $el.dataset.hint || '', value: $el.value})
        })
        syncResults(query
          ? results.filter(function (result) {
            var queryLowerCase = query.toLowerCase()
            var resultTextLowerCase = result.text.toLowerCase()
            var resultHintLowerCase = result.hint.toLowerCase()
            var resultLowerCase = resultTextLowerCase + ' ' + resultHintLowerCase
            var resultWords = resultLowerCase.split(' ')
            var resultIncludesWord = false

            var valueContains = resultTextLowerCase.indexOf(queryLowerCase) !== -1
            var hintContains = resultHintLowerCase.indexOf(queryLowerCase) !== -1

            resultWords.forEach(function (resultWord) {
              if (resultWord && queryLowerCase.includes(resultWord)) {
                resultIncludesWord = true
              }
            })

            return valueContains || hintContains || resultIncludesWord
          }) : []
        )
      },
      minLength: 3,
      autoselect: true,
      showNoOptionsFound: true,
      templates: {
        inputValue: function (result) {
          return result && result.text
        },
        suggestion: function (result) {
          return result && result.text + '<span class="autocomplete__option-hint">' + result.hint + '</span>'
        }
      },
      onConfirm: function (result) {
        var value = result && result.value
        var options = [].filter.call($select.options, function (option) {
          return option.value === value
        })

        if (options.length) {
          options[0].selected = true
        }
      }
    })

    $select.style.display = 'none'
    $select.id = $select.id + '-select'
  }

  Autocomplete.prototype.initAutoCompleteInput = function ($input) {
    var withoutNarrowingResults = this.$module.dataset.autocompleteWithoutNarrowingResults

    var list = document.getElementById($input.getAttribute('list'))
    var options = []

    if (list) {
      options = [].map.call(list.querySelectorAll('option'), function (option) {
        return option.value
      })
    }

    if (!options.length) {
      return
    }

    new window.accessibleAutocomplete({ // eslint-disable-line no-new, new-cap
      id: $input.id,
      name: $input.name,
      element: this.$module,
      showAllValues: withoutNarrowingResults,
      defaultValue: $input.value,
      autoselect: !withoutNarrowingResults,
      dropdownArrow: withoutNarrowingResults ? this.dropdownArrow : null,
      source: function (query, syncResults) {
        if (withoutNarrowingResults) {
          syncResults(options)
        } else {
          syncResults(query
            ? options.filter(function (option) {
              return option.toLowerCase().indexOf(query.toLowerCase()) !== -1
            }) : []
          )
        }
      }
    })

    $input.parentNode.removeChild($input)
  }

  Autocomplete.prototype.initAutoCompleteSearchTopics = function () {
    var $input = this.$module.querySelector('input')
    var $module = this.$module
    var millerColumns = document.querySelector('miller-columns')
    var topics = millerColumns.taxonomy.flattenedTopics

    var topicSuggestions = []

    topics.forEach(function (topic) {
      topicSuggestions.push({
        topic: topic,
        highlightedTopicName: topic.topicName.replace(/<\/?mark>/gm, ''), // strip existing <mark> tags
        breadcrumbs: topic.topicNames
      })
    })

    if (!topicSuggestions) {
      return
    }

    new window.accessibleAutocomplete({ // eslint-disable-line no-new, new-cap
      id: $input.id,
      name: $input.name,
      element: this.$module,
      minLength: 3,
      autoselect: false,
      source: function (query, syncResults) {
        var results = topicSuggestions

        syncResults(query
          ? results.filter(function (result) {
            var topicName = result.topic.topicName
            var indexOf = topicName.toLowerCase().indexOf(query.toLowerCase())
            var resultContainsQuery = indexOf !== -1
            if (resultContainsQuery) {
              // Wrap query in <mark> tags
              var queryRegex = new RegExp('(' + query + ')', 'ig')
              result.highlightedTopicName = topicName.replace(queryRegex, '<mark>$1</mark>')
            }
            return resultContainsQuery
          }) : []
        )
      },
      templates: {
        inputValue: function (result) {
          return ''
        },
        suggestion: function (result) {
          var suggestionsBreadcrumbs
          if (result && result.breadcrumbs) {
            result.breadcrumbs[result.breadcrumbs.length - 1] = result.highlightedTopicName
            suggestionsBreadcrumbs = result.breadcrumbs.join(' › ')
          }
          return suggestionsBreadcrumbs
        }
      },
      onConfirm: function (result) {
        if (result && !result.topic.selected && !result.topic.selectedChildren.length) {
          Autocomplete.prototype.triggerEvent($module, 'search-topic', result.topic)
          millerColumns.taxonomy.topicClicked(result.topic)
        }
      }
    })

    $input.parentNode.parentNode.removeChild($input.parentNode)
  }

  Autocomplete.prototype.dropdownArrow = function (config) {
    return '<svg class="' + config.className + '" style="top: 8px;" viewBox="0 0 512 512" ><path d="M256,298.3L256,298.3L256,298.3l174.2-167.2c4.3-4.2,11.4-4.1,15.8,0.2l30.6,29.9c4.4,4.3,4.5,11.3,0.2,15.5L264.1,380.9  c-2.2,2.2-5.2,3.2-8.1,3c-3,0.1-5.9-0.9-8.1-3L35.2,176.7c-4.3-4.2-4.2-11.2,0.2-15.5L66,131.3c4.4-4.3,11.5-4.4,15.8-0.2L256,298.3  z"/></svg>'
  }

  Autocomplete.prototype.triggerEvent = function (element, eventName, detail) {
    var params = {bubbles: true, cancelable: true, detail: detail || null}
    var event

    if (typeof window.CustomEvent === 'function') {
      event = new window.CustomEvent(eventName, params)
    } else {
      event = document.createEvent('CustomEvent')
      event.initCustomEvent(eventName, params.bubbles, params.cancelable, params.detail)
    }

    element.dispatchEvent(event)
  }

  Modules.Autocomplete = Autocomplete
})(window.GOVUK.Modules)
