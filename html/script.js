$(document).ready(function(){
    window.addEventListener('message', function(event){
        var data = event.data;
        if (data.action == "DrawPosition") {
            drawTimeTrialsUI(data);
        }
    });
});

function secondsTimeSpanToHMS(s) {
    return new Date(s * 1000).toISOString().slice(11, -1);
}   

function numberToDecimalPlaces(number, decimalPlaces) {
    return Number(number).toFixed(decimalPlaces)
}


function drawTimeTrialsUI(data) {
    if (!data.active) {
    $(".timetrials-container").fadeOut(300);
    $(".timetrials-container").empty();
    } else {
        $(".timetrials-container").fadeIn(300);
        $(".timetrials-container").empty();
        var element = '<div class="lap">Lap: '+ data.data.CurrentLap + '/' + data.data.TotalLaps + '</div><div class="race-checkp">CP: '+data.data.CurrentCheckpoint + '/'+data.data.TotalCheckpoints+'</div><div class="delta">Delta</div>';
        $(".timetrials-container").append(element);

        var element = '<div class="row" id="rowpos-1"> <div class="drift-pos">1</div><div class="drift-name">' + data.data.Player+'</div><div class="score">'+secondsTimeSpanToHMS(data.data.CurrentTime)+'</div></div><div class="delta-time">' + numberToDecimalPlaces(data.data.Delta, 3)+'</div>';
        // console.log(data.data.Delta)
        $(".timetrials-container").append(element);
        if (data.data.Delta <= 0) {
            $(".delta-time").css({"box-shadow": "0.05rem 0.05rem 0.4rem 0.05rem #4aa301"})
        } else {
            $(".delta-time").css({"box-shadow": "0.05rem 0.05rem 0.4rem 0.05rem #cc1103"})
        }
    }

}