var draw_graph = function(div, title, data, yaxis_label) {
  $.jqplot.config.enablePlugins = true;
  $.jqplot(div, data, { 
    title: title,
    axes: { 
      xaxis: { 
        renderer: $.jqplot.DateAxisRenderer,
        label: 'Month',
        rendererOptions: {
          tickRenderer: $.jqplot.CanvasAxisTickRenderer
        },
        tickOptions: { 
          formatString: '%b %Y', 
          angle: -30
        },
        tickInterval:'2 month',
        labelRenderer: $.jqplot.CanvasAxisLabelRenderer,
        autoscale: true
      },
      yaxis: { 
        label: yaxis_label,
        tickOptions: { 
          formatString: '%d' 
        },
      labelRenderer: $.jqplot.CanvasAxisLabelRenderer,
      autoscale: true
      }
    },
    highlighter: { 
      tooltipAxes: 'xy', 
      formatString: "%s, %s",
    },
   cursor: { 
     tooltipLocation: 'sw' 
   },
   series: [{
     trendline: {
       color: "#cccccc",
       lineWidth: 1
     }
   }]
 })
}
