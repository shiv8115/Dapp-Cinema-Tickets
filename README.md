# Dapp Cinema Ticket Booking

Here is an overview of the key components and functions of the smart contract:

1. **Ownable**: The contract inherits from the **Ownable** contract in the OpenZeppelin library, which provides basic access control by allowing only the contract owner to execute certain functions.
2. **Counters**: The contract uses the **Counters** library from OpenZeppelin to keep track of the total number of movies, tickets, and time slots created.
3. **MovieStruct**: This struct defines the properties of a movie, including **id**, **name**, **imageUrl**, **genre**, **description**, **timestamp**, and **deleted**.
4. **TicketStruct**: This struct defines the properties of a ticket, including **id**, **movieId**, **slotId**, **owner**, **cost**, **timestamp**, **day**, and **refunded**.
5. **TimeSlotStruct**: This struct defines the properties of a time slot for a movie screening, including **id**, **movieId**, **ticket cost**, **startTime**, **endTime**, **capacity**, **seats**, **deleted**, **completed**, **day**, and **balance**.
6. **Action** event: This event is emitted to indicate successful actions performed within the contract.
7. **balance** variable: This variable stores the contract’s current balance.
8. Various mappings: The contract uses mappings to store and retrieve data related to movies, time slots, and ticket holders.

**The contract provides the following functions:**

- **addMovie**: Allows the contract owner to add a new movie to the system by providing the necessary details such as **name**, **imageUrl**, **genre**, and **description**.
- **updateMovie**: Allows the contract owner to update the details of an existing movie by specifying the **movieId** and providing the updated information.
- **deleteMovie**: Allows the contract owner to delete a movie from the system by specifying the **movieId**. However, it can only be deleted if there are no purchased tickets associated with it.
- **getMovies**: Retrieves an array of all available movies in the system.
- **getMovie**: Retrieves the details of a specific movie by providing its **id**.
- **addTimeslot**: Allows the contract owner to add a time slot for a movie screening by specifying the **movieId** and providing arrays of **ticketCosts**, **startTimes**, **endTimes**, **capacities**, and **viewingDays** for the time slots.
- **deleteTimeSlot**: Allows the contract owner to delete a time slot for a movie screening by specifying the **movieId** and **slotId**. The function refunds all ticket holders for the canceled time slot.
- **markTimeSlot**: Allows the contract owner to mark a time slot as completed by specifying the **movieId** and **slotId**. The function adds the balance of the completed time slot to the contract’s overall balance.
- **getTimeSlotsByDay**: Retrieves an array of time slots available for a specific day by specifying the **day**.
- **getTimeSlot**: Retrieves the details of a specific time slot by providing its **slotId**.
- **getTimeSlots**: Retrieves an array of time slots available for a specific movie by specifying the **movieId**.
- **buyTicket**: Allows users to purchase tickets for a movie by specifying the **movieId**, **slotId**, and the number of **tickets** to purchase. The function checks for availability, verifies the payment amount, and records the ticket details.
- **getMovieTicketHolders**: Retrieves an array of ticket holders for a specific movie by providing its **movieId**.
- **getTicket**: Retrieves the details of a specific ticket by providing its **ticketId**.
- **refundTicket**: Allows the contract owner to refund a ticket by specifying the **ticketId**. The function refunds the ticket owner and updates the ticket’s **refunded** status.
- **getContractBalance**: Retrieves the current balance of the contract.
- **withdrawBalance**: Allows the contract owner to withdraw the contract’s balance.
