function initElmPorts(app) {
    // Compute streaming
    var sources = {}
  
    function sendEventToElm(address) {
      return function(event) {
        app.ports.receiveEvent.send({
          address: address,
          data: event.data, // Can't be null according to spec
          eventType: event.type || null,
          id: event.id || null,
        })
      }
    }
  
    function newEventSource(address) {
      sources[address] = new EventSource(address)
      return sources[address]
    }
    
    function deleteEventSource(address) {
      sources[address].close()
      delete sources[address]
    }
  
    app.ports.openStream.subscribe(function (args) {
      console.log(`stream: ${args[0]}`)
      var address = args[0]
  
      var eventSource = newEventSource(address)
      eventSource.onerror = function (err) {
        console.log(`EventSource failed: ${JSON.stringify(err)}`)
      }
      eventSource.addEventListener('results', sendEventToElm(address))
      eventSource.addEventListener('alert', sendEventToElm(address))
      eventSource.addEventListener('error', sendEventToElm(address))
      eventSource.addEventListener('done', function (event) {
        console.log('Done')
        deleteEventSource(address)
        // Note: 'done:true' is sent in progress too. But we want a 'done' for the entire stream in case we don't see it.
        sendEventToElm(address)({ type: 'done', data: '' })
      })
    })
  
    app.ports.emitInput.subscribe(function (args) {})
  }
  