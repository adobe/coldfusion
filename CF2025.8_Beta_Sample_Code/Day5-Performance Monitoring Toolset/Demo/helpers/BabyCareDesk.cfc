/**
 * Baby Care Desk tool CFC for Mintu's Baby Care Assistant.
 * Exposes baby profile lookup, routine status, care task creation/retrieval as AI tools.
 */
component {

    /**
     * @mcpTool true
     * @mcpDescription Look up a family member or baby by their ID and return their profile information.
     */
    remote struct function lookupFamilyMember(
        required string memberId hint="The family member ID, e.g. BABY-001, PARENT-001"
    ) {
        var members = {
            "BABY-001":   { id: "BABY-001",   name: "Mintu",              role: "Baby",     dob: "2026-03-15", age: "1 month",   weight: "3.8 kg", height: "52 cm", bloodType: "O+", pediatrician: "Dr. Sharma" },
            "PARENT-001": { id: "PARENT-001",  name: "Sandeep (Papa)",     role: "Father",   email: "sandeep@family.com",  phone: "555-2001", notes: "Primary caregiver during evenings" },
            "PARENT-002": { id: "PARENT-002",  name: "Mama",               role: "Mother",   email: "mama@family.com",     phone: "555-2002", notes: "Primary caregiver during daytime, breastfeeding" },
            "FAMILY-001": { id: "FAMILY-001",  name: "Grandma (Nani)",     role: "Grandma",  email: "nani@family.com",     phone: "555-2003", notes: "Helps with baby care on weekends" },
            "FAMILY-002": { id: "FAMILY-002",  name: "Grandpa (Nana)",     role: "Grandpa",  email: "nana@family.com",     phone: "555-2004", notes: "Loves singing lullabies to Mintu" }
        };

        if (structKeyExists(members, uCase(arguments.memberId))) {
            return { success: true, member: members[uCase(arguments.memberId)] };
        }
        return { success: false, message: "Family member #arguments.memberId# not found." };
    }

    /**
     * @mcpTool true
     * @mcpDescription Check the current status of a baby care routine or activity.
     */
    remote struct function checkRoutineStatus(
        required string routineName hint="Name of the routine to check, e.g. 'Feeding', 'Sleep', 'Diaper', 'Bath', 'Tummy Time'"
    ) {
        var routines = {
            "FEEDING":    { status: "on-schedule",  lastTime: "2:30 PM", nextDue: "5:30 PM",  frequency: "Every 3 hours",   notes: "Breastfeeding well, gaining weight steadily", dailyCount: 8 },
            "SLEEP":      { status: "napping",      lastTime: "3:00 PM", nextDue: "4:30 PM",  frequency: "16-17 hours/day", notes: "Currently napping, last wake window was 45 min", napCount: 5 },
            "DIAPER":     { status: "due-soon",     lastTime: "2:00 PM", nextDue: "3:30 PM",  frequency: "Every 2-3 hours", notes: "8 wet diapers today (healthy)", dailyCount: 8 },
            "BATH":       { status: "completed",    lastTime: "10:00 AM", nextDue: "Tomorrow 10 AM", frequency: "Once daily", notes: "Used gentle baby wash, no skin irritation" },
            "TUMMY TIME": { status: "pending",      lastTime: "11:00 AM", nextDue: "After next nap", frequency: "3-5 min, 2-3x daily", notes: "Mintu is getting stronger at lifting head!", dailyCount: 1 },
            "VACCINATION":{ status: "upcoming",     lastTime: "2026-03-20", nextDue: "2026-04-20", frequency: "Per schedule", notes: "6-week vaccines due: DTaP, IPV, Hib, PCV13, Rotavirus" },
            "CHECKUP":    { status: "scheduled",    lastTime: "2026-04-01", nextDue: "2026-05-15", frequency: "Monthly for first 6 months", notes: "Dr. Sharma - well baby visit" }
        };

        var key = uCase(trim(arguments.routineName));
        if (structKeyExists(routines, key)) {
            return { success: true, routine: arguments.routineName, data: routines[key] };
        }
        return { success: true, routine: arguments.routineName, data: { status: "unknown", notes: "Routine not tracked. Try: Feeding, Sleep, Diaper, Bath, Tummy Time, Vaccination, Checkup" } };
    }

    /**
     * @mcpTool true
     * @mcpDescription Create a new care task or reminder for Mintu.
     */
    remote struct function createCareTask(
        required string subject     hint="Short description of the care task",
        required string description hint="Full description of the task or reminder",
        required string priority    hint="Priority level: P1 (Urgent - health concern), P2 (Important - routine), P3 (Normal), P4 (Low - nice to have)"
    ) {
        var taskId = "CARE-" & dateFormat(now(), "YYYYMMDD") & "-" & randRange(1000, 9999);
        var assignedTo = { P1: "Both Parents + Pediatrician", P2: "Primary Caregiver", P3: "Available Parent", P4: "Any Family Member" };

        return {
            success:    true,
            taskId:     taskId,
            subject:    arguments.subject,
            priority:   arguments.priority,
            status:     "Pending",
            assignedTo: structKeyExists(assignedTo, uCase(arguments.priority)) ? assignedTo[uCase(arguments.priority)] : "Available Parent",
            created:    dateTimeFormat(now(), "yyyy-mm-dd HH:nn:ss"),
            reminder:   { P1: "Immediately", P2: "Within 1 hour", P3: "Today", P4: "This week" }[uCase(arguments.priority)] ?: "This week"
        };
    }

    /**
     * @mcpTool true
     * @mcpDescription Get the current status of an existing care task by task ID.
     */
    remote struct function getTaskStatus(
        required string taskId hint="The task ID, e.g. CARE-20260415-1234"
    ) {
        var knownTasks = {
            "CARE-DEMO-001": { status: "In Progress", priority: "P2", subject: "Schedule 6-week vaccination",   assignedTo: "Papa",              lastUpdate: "Appointment booked for April 20" },
            "CARE-DEMO-002": { status: "Completed",   priority: "P3", subject: "Buy newborn diapers size 1",    assignedTo: "Mama",              lastUpdate: "Purchased Pampers Swaddlers NB" },
            "CARE-DEMO-003": { status: "Pending",     priority: "P1", subject: "Baby has mild rash - consult",  assignedTo: "Both Parents + Dr", lastUpdate: "Monitoring, applying diaper cream" }
        };

        if (structKeyExists(knownTasks, uCase(arguments.taskId))) {
            return { success: true, taskId: arguments.taskId, data: knownTasks[uCase(arguments.taskId)] };
        }

        if (left(arguments.taskId, 5) == "CARE-") {
            return {
                success:  true,
                taskId: arguments.taskId,
                data: { status: "Pending", priority: "P3", subject: "Recently created task", assignedTo: "Available Parent", lastUpdate: "Task received, awaiting action" }
            };
        }

        return { success: false, message: "Task #arguments.taskId# not found." };
    }
}
