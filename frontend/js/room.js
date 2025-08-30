async function getRoomByToken(token) {
  if (!token) {
    return null;
  }

  try {
    const response = await axios.get(
      "http://192.168.1.105:3000/api/v1/rooms/token/" + token
    );

    console.log(response);

    if (response.data) return response.data[0];
    else return {};
  } catch (error) {
    console.log(error);

    return { error };
  }
}

function updateTimer(room, el) {
  const timeLeft = room.time;

  const isNegative = timeLeft < 0;
  const isEnding = timeLeft < 60;
  const toConclude = timeLeft < 300;

  const absoluteTimeLeft = timeLeft < 0 ? timeLeft * -1 : timeLeft;

  // Calculate minutes and seconds
  let minutes = Math.floor(absoluteTimeLeft / 60);
  let seconds = absoluteTimeLeft % 60;

  // Calc percentage
  let percentage = Math.floor((timeLeft / 3000) * 100); // 3000s = 50min, padrão de tempo
  if (percentage > 100) percentage = 100;
  else if (percentage < 0) percentage = 0;

  // Update the display with the new time
  el.textContent = `${minutes.toString().padStart(2, "0")}:${seconds
    .toString()
    .padStart(2, "0")}`;

  if (isEnding) {
    el.style.color = "#FF0000";
  } else {
    el.style.color = "#FFF";
  }

  if (isNegative) {
    el.textContent = "-" + el.textContent;
  }

  return { timeLeft, toConclude, isEnding, isNegative, percentage };
}
