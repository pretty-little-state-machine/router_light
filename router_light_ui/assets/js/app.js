// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import {Socket} from "phoenix"
import topbar from "topbar"
import {LiveSocket} from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let hooks = {}

hooks.dashboard = {
    mounted() {
        function seconds_to_hhmmss(secs) {
            
            const seconds = Math.floor(secs % 60);
            const minutes = Math.floor((secs / 60) % 60);
            const hours = Math.floor((secs / 3600 ) % 24)
          
            return [
              ("00" + hours.toString()).slice(-2),
              ("00" + minutes.toString()).slice(-2), 
              ("00" + seconds.toString()).slice(-2),
            ].join(':');
        }
        
        function update_log(messages) {
            let result = ''
            messages.forEach(message => {
                if ( 0 !== message.delta_t) {
                    let date = new Date(message.delta_t);
                    result += `
                    <div style="clear: both; margin-bottom: 10px; padding: 5px">
                        <div class="nerv-cyan-text nerv-smear-cyan" style="float: left; min-width: 125px;">${date.toLocaleTimeString()}</div>
                        <div style="float: left" class="nerv-orange-text nerv-smear-red">${message.message}</div>
                    </div>
                `
                }
            });
            document.getElementById("log-content").innerHTML = result;
        }

        function set_last_event_timer(ms) {
            let hms_ele = document.getElementById("timer-hhmmss")
            let msecs_ele = document.getElementById("timer-msecs")
     
            const hh_mm_ss = seconds_to_hhmmss(ms / 1000)

            hms_ele.innerHTML = hh_mm_ss
            msecs_ele.innerHTML = ":" + ("000" + (1000 - ms).toString()).slice(-3)
        }

        function build_latency_bars(latency_value, dom_parent_element, latency_value_element, latency_suffix_element) {
            dom_parent_element.innerHTML = ''
            if (latency_value > 0) {
                latency_value_element.innerHTML = latency_value;
                latency_suffix_element.innerHTML = "MSECS";

                let num_bars = Math.ceil(latency_value / 10)

                // Clamp the number of bars we build
                if (num_bars > 15) { num_bars = 15 }
                // Filled bars up to the penultimate bar
                for(let i = 1; i <= num_bars -1; i++) {
                    let filled_bar = document.createElement('div');
                    filled_bar.className = 'nerv-progress-item nerv-progress-filled'
                    dom_parent_element.appendChild(filled_bar)
                }
                // The last filled bar should be flashing   
                let filled_bar = document.createElement('div');
                filled_bar.className = 'nerv-progress-item nerv-progress-filled nerv-progress-flashing'
                dom_parent_element.appendChild(filled_bar)
                // Unfilled bars
                for(let i = 1; i <= 15 - num_bars; i++) {
                    let filled_bar = document.createElement('div');
                    filled_bar.className = 'nerv-progress-item'
                    dom_parent_element.appendChild(filled_bar)
                }
            } else {
                latency_value_element.innerHTML = "";
                latency_suffix_element.innerHTML = "";

                let errror_message = document.createElement('div');
                errror_message.className = 'nerv-bigger-text nerv-emergency-container nerv-red-text nerv-text-flash nerv-smear-red'
                errror_message.innerHTML = "SLA EMERGENCY"
                dom_parent_element.appendChild(errror_message);
            }
        }

        function set_signalling_status(color) {
            let ele = document.getElementById("status-color")
            switch (color) {
                case "BLUE": 
                    ele.className = "nerv-cyan-text "
                    ele.innerHTML = "BLUE"
                    break;
                case "GREEN": 
                    ele.className = "nerv-green-text"
                    ele.innerHTML = "GREEN"
                    break;
                case "PURPLE": 
                    ele.className = "nerv-purple-text "
                    ele.innerHTML = "PURPLE"
                    break;
                case "YELLOW": 
                    ele.className = "nerv-orange-text "
                    ele.innerHTML = "YELLOW"
                    break;
                case "RED": 
                    ele.className = "nerv-red-text nerv-text-flash"
                    ele.innerHTML = "RED"
                    break;
                default:
                    ele.className = "nerv-red-text nerv-text-flash"
                    ele.innerHTML = "UNKNOWN"
            }
        }

        let t1_ctx = document.getElementById("t1_traffic").getContext('2d')
        let t1_chart = new Chart(t1_ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    label: 'Traffic_In',
                    borderColor: 'rgba(0, 240, 50, 1.0)',
                    data: []
                },
                {
                    label: 'Traffic_Out',
                    borderColor: 'rgba(0, 255, 192, 1.0)',
                    data: []
                },
            ]
            },        
            options: {
                animation: {
                    duration: 0
                },
                plugins: {
                    legend: {
                        display: false
                    }
                },
                elements: {
                    point:{
                        radius: 0
                    },
                    line: {
                        cubicInterpolationMode: 'monotone',
                        tension: 0,
                        borderWidth: 1,
                    }
                },
                scales: {
                    y: {
                        grid: {
                            color: "rgba(253, 169, 43, .2)",
                        },
                        ticks: {
                            stepSize: 300
                        },
                        min: -2000,
                        max: 2000,
                    },
                    x: {
                        ticks: {
                            maxTicksLimit: 11
                        },
                        grid: {
                            color: "rgba(253, 169, 43, .2)",
                            drawTicks: false
                        },
                    }
                },
            }
        });

        let lte_ctx =  document.getElementById("lte_traffic").getContext('2d')
        let lte_chart = new Chart(lte_ctx, {
            type: 'line',
            data: {
                labels: [],
                datasets: [{
                    borderColor: 'rgba(0, 240, 50, 1.0)',
                    data: []
                },
                {
                    borderColor: 'rgba(0, 255, 192, 1.0)',
                    data: []
                },
            ]
            },        
            options: {
                animation: {
                    duration: 0
                },
                plugins: {
                    legend: {
                        display: false
                    }
                },
                elements: {
                    point:{
                        radius: 0
                    },
                    line: {
                        cubicInterpolationMode: 'monotone',
                        tension: 0,
                        borderWidth: 1,
                    }
                },
                scales: {
                    y: {
                        grid: {
                            color: "rgba(253, 169, 43, .2)",
                        },
                        ticks: {
                            stepSize: 5000
                        },
                        min: -40000,
                        max: 40000,
                    },
                    x: {
                        ticks: {
                            maxTicksLimit: 11
                        },
                        grid: {
                            color: "rgba(253, 169, 43, .2)",
                            drawTicks: false
                        },
                    }
                },
            }

        });

        this.handleEvent("dashboard", ({
                status_color,
                last_event,
                t1_latency, 
                t1_traffic_in,
                t1_traffic_out,
                lte_latency,
                lte_traffic_in,
                lte_traffic_out,
                labels,
                messages,
            }) => {
            set_signalling_status(status_color);
            set_last_event_timer(last_event);
            /* Latency Bar Charts */
            build_latency_bars(t1_latency, 
                document.getElementById("t1-latency-bars"), 
                document.getElementById("t1-latency-value"),
                document.getElementById("t1-latency-suffix"));
            build_latency_bars(lte_latency, 
                document.getElementById("lte-latency-bars"), 
                document.getElementById("lte-latency-value"),
                document.getElementById("lte-latency-suffix"));
            /* Graphs */
            t1_chart.data.datasets[0].data = t1_traffic_in;
            t1_chart.data.datasets[1].data = t1_traffic_out;
            t1_chart.data.labels = labels;
            t1_chart.update();
            lte_chart.data.datasets[0].data = lte_traffic_in;
            lte_chart.data.datasets[1].data = lte_traffic_out;
            lte_chart.data.labels = labels;
            lte_chart.update();
            /* Logs */
            update_log(messages);
        })
    }
}

let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => topbar.show())
window.addEventListener("phx:page-loading-stop", info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket
