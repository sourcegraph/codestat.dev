function initElmPorts(app) {
    // Compute streaming
    var sources = {}
  
    function sendEventToElm(address) {
      return function(event) {
        app.ports.receiveEvent.send({
          address: address,
          data: event.data || "", // Can be undefined in the case of connection error
          eventType: event.type || null,
          id: event.id || null,
        })
      }
    }
    
    app.ports.openStream.subscribe(function (args) {
      console.log(`stream: ${args[0]}`)
      var address = args[0]
  
      var eventSource = new EventSource(address)
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
  