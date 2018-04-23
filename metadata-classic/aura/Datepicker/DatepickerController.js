({
	doInit : function(component, event, helper) {
		var month = component.get('v.month');
		var year = component.get('v.year');
		if ($A.util.isEmpty(month) || $A.util.isEmpty(year)) {
			var today = new Date();
			month = today.getMonth() + 1;
			year = today.getFullYear();
			component.set('v.month', month);
			component.set('v.year', year);
		} else {
			helper.setMonthName(component);
		}
		helper.generateCalendar(component, year, month);
	},
	handleMonthChange: function(component, event, helper) {
		helper.setMonthName(component);
	},
	nextMonth: function(component, event, helper) {
		helper.nextMonth(component);
	},
	prevMonth: function(component, event, helper) {
		helper.prevMonth(component);
	},
	selectDate: function(component, event, helper) {
		var target = event.currentTarget;
		var selectedMonth = parseInt(target.dataset.month, 10);
		var selectedDay = parseInt(target.dataset.day, 10);
		var selectedYear = parseInt(target.dataset.year, 10);
		component.set('v.selectedMonth', selectedMonth);
		component.set('v.selectedDay', selectedDay);
		component.set('v.selectedYear', selectedYear);
		var month = component.get('v.month');
		if (month != selectedMonth) {
			if (selectedMonth < month) {
				helper.prevMonth(component);
			} else {
				helper.nextMonth(component);
			}
		}
		var appEvent = $A.get('e.c:DateSelected');
		appEvent.setParams({
			month: selectedMonth,
			day: selectedDay,
			year: selectedYear
		});
		appEvent.fire();
	},
	selectToday: function(component, event, helper) {
		var newDate = new Date ();
		var selectedMonth = newDate.getMonth() + 1;
		var selectedDay = newDate.getDate();
		var selectedYear = newDate.getFullYear();
		component.set('v.selectedMonth', selectedMonth);
		component.set('v.selectedDay', selectedDay);
		component.set('v.selectedYear', selectedYear);
		var month = component.get('v.month');
		if (month != selectedMonth) {
			if (selectedMonth < month) {
				helper.prevMonth(component);
			} else {
				helper.nextMonth(component);
			}
		}
		var appEvent = $A.get('e.c:DateSelected');
		appEvent.setParams({
			month: selectedMonth,
			day: selectedDay,
			year: selectedYear
		});
		appEvent.fire();
	}
})