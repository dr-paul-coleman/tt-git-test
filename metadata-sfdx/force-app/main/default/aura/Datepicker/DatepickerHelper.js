({
	getDaysInMonth : function(year, month) {
		return 32 - (new Date(year, month, 32)).getDate();
	},
	getFirstDayOfMonth: function(year, month) {
		return new Date(year, month, 1).getDay();
	},
	addDaysToDate: function(myDate, days) {
		myDate.setDate(myDate.getDate() + days);
	},
	nextMonth: function(component) {
		var month = component.get('v.month');
		var year = component.get('v.year');
		var daysInMonth = this.getDaysInMonth(year, month - 1);
		var newDate = new Date(year, month - 1, 1);
		this.addDaysToDate(newDate, daysInMonth);
		component.set('v.month', newDate.getMonth() + 1);
		component.set('v.year', newDate.getFullYear());
		this.generateCalendar(component);
	},
	prevMonth: function(component) {
		var month = component.get('v.month');
		var year = component.get('v.year');
		var newDate = new Date(year, month - 1, 1);
		this.addDaysToDate(newDate, -1);
		component.set('v.month', newDate.getMonth() + 1);
		component.set('v.year', newDate.getFullYear());
		this.generateCalendar(component);
	},
	setMonthName: function(component) {
		var monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
		var month = component.get('v.month');
		component.set('v.monthName', monthNames[month - 1]);
	},
	generateCalendar: function(component) {
		var month = component.get('v.month');
		var year = component.get('v.year');
		var daysOfWeek = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
		var currentDate = new Date(year, month - 1, 1);
		var daysInMonth = this.getDaysInMonth(year, month - 1);
		var prevDate = new Date(year, month - 1, 1);
		this.addDaysToDate(prevDate, -1);
		var nextDate = new Date(year, month - 1, 1);
		this.addDaysToDate(nextDate, daysInMonth);
		var daysInPrevMonth = this.getDaysInMonth(prevDate.getFullYear(), prevDate.getMonth());
		var calendar = [];
		var currentDay = 1;
		var firstDay = this.getFirstDayOfMonth(year, month - 1);
		var today = new Date();
		var todayYear = today.getFullYear();
		var todayMonth = today.getMonth() + 1;
		var todayDate = today.getDate();
		if (firstDay != 0) {
			var week = [];
			for (var i = 0; i < 7; i++) {
				if (i < firstDay) {
					week.push({
						month: prevDate.getMonth() + 1,
						day: daysInPrevMonth - firstDay + 1 + i,
						year: prevDate.getFullYear(),
						isToday: false,
						weekDay: daysOfWeek[i]
					});
				} else {
					week.push({
						month: month,
						day: currentDay,
						year: year,
						isToday: todayYear == year && todayMonth == month && todayDate == currentDay,
						weekDay: daysOfWeek[i]
					});
					currentDay++;
				}
			}
			calendar.push(week);
		}
		while (currentDay <= daysInMonth) {
			var week = [];
			var nextMonthDay = 1;
			for (var i = 0; i < 7; i++) {
				if (currentDay <= daysInMonth) {
					week.push({
						month: month,
						day: currentDay,
						year: year,
						isToday: todayYear == year && todayMonth == month && todayDate == currentDay,
						weekDay: daysOfWeek[i]
					});
					currentDay++;
				} else {
					week.push({
						month: nextDate.getMonth() + 1,
						day: nextMonthDay,
						year: nextDate.getFullYear(),
						isToday: false,
						weekDay: daysOfWeek[i]
					});
					nextMonthDay++;
				}
			}
			calendar.push(week);
		}
		component.set('v.calendar', calendar);
	}
})